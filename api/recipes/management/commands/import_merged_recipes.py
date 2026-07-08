import csv
import io
import re

import requests
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError

from recipes.models import Recipe

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


class Command(BaseCommand):
    help = 'Import merged recipes from a CSV file or URL into the database.'

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
            help='Username to assign as recipe creator (default: first superuser)',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        limit = options['limit']

        User = get_user_model()
        owner_username = options.get('owner', '').strip()
        if owner_username:
            try:
                owner = User.objects.get(username=owner_username)
            except User.DoesNotExist:
                raise CommandError(f"User '{owner_username}' not found.")
        else:
            owner = User.objects.filter(is_superuser=True).order_by('id').first()
            if not owner:
                raise CommandError("No superuser found. Create one with createsuperuser or pass --owner.")
        self.stdout.write(f"Assigning recipes to owner: {owner.username} (id={owner.id})")

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
        imported = skipped = errors = 0

        for row in reader:
            title = (row.get('title') or '').strip()
            if not title:
                errors += 1
                continue

            if title in existing_titles:
                skipped += 1
                continue

            instructions = _parse_instructions(row.get('recipeInstructions', ''))
            if not instructions:
                skipped += 1
                continue

            tags = _parse_tags(row.get('tags', ''))

            if dry_run:
                imported += 1
                if imported <= 5:
                    self.stdout.write(
                        f"  [dry-run] '{title[:60]}' | "
                        f"prep={_parse_iso_duration(row.get('prepTime'))} "
                        f"cook={_parse_iso_duration(row.get('cookTime'))} "
                        f"servings={_parse_servings(row.get('recipeYield'))} "
                        f"tags={tags} steps={len(instructions)}"
                    )
            else:
                try:
                    recipe = Recipe(
                        title=title,
                        description=(row.get('description') or '').strip(),
                        web_image_url=(row.get('image') or '').strip() or None,
                        preparation_time=_parse_iso_duration(row.get('prepTime')),
                        cooking_time=_parse_iso_duration(row.get('cookTime')),
                        servings=_parse_servings(row.get('recipeYield')),
                        instructions=instructions,
                        tags=tags,
                        created_by=owner,
                    )
                    recipe.save()
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
                f"Done — imported: {imported}, skipped: {skipped}, errors: {errors}"
            )
        )
