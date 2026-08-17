import csv
import io
import re

import requests
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError

from recipes.ingredient_parsing import parse_ingredient
from recipes.models import Ingredient, Recipe

# CSV 'source' column -> (importer username, Recipe.source value).
# Importer accounts already exist in prod from a prior import_allrecipes.py run;
# reusing them keeps 0020_backfill_recipe_source's assumptions (and future
# per-source auditing) correct instead of attributing these to the --owner user.
_IMPORTER_BY_CSV_SOURCE = {
    'AllRecipes': ('allrecipes_importer', Recipe.SOURCE_CATALOG),
    'BBC': ('bbc_good_food_importer', Recipe.SOURCE_CATALOG),
}

_MEAL_TYPE_MAP = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
    'dessert': 'Dessert',
    'main-dish': 'Dinner',
    'main dish': 'Dinner',
    'side-dish': 'Dinner',
    'appetizer': 'Snack',
    'brunch': 'Breakfast',
}

_VALID_TAGS = {'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'}


def _parse_iso_duration(value):
    """PT1H30M → 90, PT45M → 45, empty/bad → None"""
    if not value:
        return None
    m = re.match(r'PT(?:(\d+)H)?(?:(\d+)M)?', value.strip())
    if not m:
        return None
    hours = int(m.group(1) or 0)
    mins = int(m.group(2) or 0)
    result = hours * 60 + mins
    return result if result > 0 else None


def _parse_servings(value):
    """'4 serving(s)' → 4, '6' → 6, bad → None"""
    if not value:
        return None
    m = re.search(r'\d+', str(value))
    return int(m.group()) if m else None


def _parse_tags(raw):
    """
    'meal-type_dinner; meal-type_main-dish; dish-type_...' → ['Dinner']
    Returns at most one meal-type tag; model.save() assigns one if empty.
    """
    tags = set()
    for part in raw.split(';'):
        part = part.strip().lower()
        for prefix in ('meal-type_', 'dish-type_', 'theme_', 'occasion_', 'technique_'):
            if part.startswith(prefix):
                part = part[len(prefix):]
                break
        if part in _MEAL_TYPE_MAP:
            tags.add(_MEAL_TYPE_MAP[part])
    valid = [t for t in tags if t in _VALID_TAGS]
    return valid[:1]


def _parse_instructions(raw):
    """Semicolon-separated steps → list of non-empty strings."""
    if not raw:
        return []
    return [s.strip() for s in raw.split(';') if s.strip()]


def _get_or_create_ingredient(line):
    parsed = parse_ingredient(line)
    name = parsed['name']
    if not name:
        return None
    quantity = round(parsed['quantity'], 4) if parsed['quantity'] is not None else None
    ingredient, _ = Ingredient.objects.get_or_create(
        name=name,
        quantity_unit=parsed['quantity_unit'],
        preparation=parsed['preparation'],
        defaults={
            # Populate the numeric fields the API and app actually read, not just
            # the combined string — otherwise every line renders as "1 <name>".
            'quantity': quantity,
            'unit': parsed['unit'],
            'original_text': parsed['original_text'],
        },
    )
    return ingredient


class Command(BaseCommand):
    help = 'Import merged recipes from a CSV file or URL into the database. Recipes without an image are skipped.'

    def add_arguments(self, parser):
        source = parser.add_mutually_exclusive_group(required=True)
        source.add_argument('--file', help='Local path to the CSV file')
        source.add_argument('--url', help='HTTP(S) URL to the CSV (e.g. GCS signed URL)')
        parser.add_argument(
            '--dry-run', action='store_true',
            help='Parse and validate without writing to the database',
        )
        parser.add_argument(
            '--limit', type=int, default=0,
            help='Stop after importing this many rows (0 = no limit)',
        )
        parser.add_argument(
            '--owner', default='',
            help=(
                "Username to assign as recipe creator for rows whose CSV 'source' "
                "isn't AllRecipes/BBC (default: first superuser). Recognized sources "
                "are attributed to their existing importer account instead."
            ),
        )

    def _resolve_owner(self, options):
        User = get_user_model()
        owner_username = options.get('owner', '').strip()
        if owner_username:
            try:
                return User.objects.get(username=owner_username)
            except User.DoesNotExist:
                raise CommandError(f"User '{owner_username}' not found.")
        owner = User.objects.filter(is_superuser=True).order_by('id').first()
        if not owner:
            raise CommandError("No superuser found. Create one with createsuperuser or pass --owner.")
        return owner

    def _resolve_importer(self, username):
        User = get_user_model()
        user, created = User.objects.get_or_create(
            username=username,
            defaults={'email': f'{username}@system.com', 'is_active': False},
        )
        if created:
            self.stdout.write(f"Created system importer user: {username}")
        return user

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        limit = options['limit']

        fallback_owner = self._resolve_owner(options)
        self.stdout.write(f"Fallback owner for unrecognized sources: {fallback_owner.username}")
        importer_cache = {}

        if options['file']:
            try:
                f = open(options['file'], encoding='utf-8')
            except OSError as e:
                raise CommandError(f"Cannot open file: {e}")
            reader = csv.DictReader(f)
        else:
            self.stdout.write(f"Fetching CSV from {options['url']} …")
            resp = requests.get(options['url'], timeout=60)
            if resp.status_code != 200:
                raise CommandError(f"Failed to fetch CSV: HTTP {resp.status_code}")
            reader = csv.DictReader(io.StringIO(resp.text))

        existing_titles = set(Recipe.objects.values_list('title', flat=True))
        imported = skipped = no_image = errors = 0

        for row in reader:
            title = (row.get('title') or '').strip()
            if not title:
                errors += 1
                continue

            if title in existing_titles:
                skipped += 1
                continue

            # Non-negotiable: recipes sourced from the internet must have an image.
            image_url = (row.get('image') or '').strip()
            if not image_url:
                no_image += 1
                continue

            instructions = _parse_instructions(row.get('recipeInstructions', ''))
            if not instructions:
                skipped += 1
                continue

            tags = _parse_tags(row.get('tags', ''))
            ingredient_lines = [i.strip() for i in (row.get('recipeIngredients') or '').split(';') if i.strip()]

            csv_source = (row.get('source') or '').strip()
            importer_username, recipe_source = _IMPORTER_BY_CSV_SOURCE.get(
                csv_source, (None, Recipe.SOURCE_IMPORT)
            )
            if importer_username:
                if importer_username not in importer_cache:
                    importer_cache[importer_username] = self._resolve_importer(importer_username)
                owner = importer_cache[importer_username]
            else:
                owner = fallback_owner

            if dry_run:
                imported += 1
                if imported <= 5:
                    self.stdout.write(
                        f"  [dry-run] '{title[:60]}' | owner={owner.username} source={recipe_source} | "
                        f"prep={_parse_iso_duration(row.get('prepTime'))} "
                        f"cook={_parse_iso_duration(row.get('cookTime'))} "
                        f"servings={_parse_servings(row.get('recipeYield'))} "
                        f"tags={tags} steps={len(instructions)} ingredients={len(ingredient_lines)}"
                    )
            else:
                try:
                    recipe = Recipe(
                        title=title,
                        description=(row.get('description') or '').strip(),
                        web_image_url=image_url,
                        preparation_time=_parse_iso_duration(row.get('prepTime')),
                        cooking_time=_parse_iso_duration(row.get('cookTime')),
                        servings=_parse_servings(row.get('recipeYield')),
                        instructions=instructions,
                        tags=tags,
                        source=recipe_source,
                        created_by=owner,
                    )
                    recipe.save()
                    for line in ingredient_lines:
                        ingredient = _get_or_create_ingredient(line)
                        if ingredient:
                            recipe.ingredients.add(ingredient)
                    existing_titles.add(title)
                    imported += 1
                    if imported % 500 == 0:
                        self.stdout.write(f"  {imported} imported …")
                except Exception as e:
                    errors += 1
                    if errors <= 10:
                        self.stderr.write(f"  Error on '{title[:50]}': {e}")
                    continue

            if limit and imported >= limit:
                break

        self.stdout.write(
            self.style.SUCCESS(
                f"{'[DRY RUN] ' if dry_run else ''}"
                f"Done — imported: {imported}, skipped: {skipped}, "
                f"no_image (rejected): {no_image}, errors: {errors}"
            )
        )
