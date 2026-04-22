"""
Management command: import_usda_bulk

Pre-populates the NutritionData table by querying the USDA FoodData Central API
for a list of ingredient names.  Useful for seeding the cache before the app
receives live traffic so that per-recipe nutrition calculations hit the local DB
rather than hammering the API every time.

Usage:
    python manage.py import_usda_bulk --file ingredients.txt
    python manage.py import_usda_bulk --names "garlic" "chicken breast" "olive oil"
    python manage.py import_usda_bulk --from-db        # pull all unique names from existing Ingredients

Options:
    --file PATH       Path to a plain-text file with one ingredient per line.
    --names ...       One or more ingredient names as positional CLI args.
    --from-db         Import names found in the Ingredient table (usda_name or name).
    --delay SECONDS   Seconds to sleep between API calls (default: 0.5; be kind to USDA).
    --skip-existing   Skip names that already have a NutritionData record.
"""

import time
from django.core.management.base import BaseCommand, CommandError
from recipes.models import NutritionData, Ingredient
from recipes.usda_api import USDAClient
from recipes.nutrition_service import _clean_for_usda


class Command(BaseCommand):
    help = "Bulk-import nutrition data from the USDA FoodData Central API into the local cache."

    def add_arguments(self, parser):
        source = parser.add_mutually_exclusive_group(required=True)
        source.add_argument(
            '--file',
            metavar='PATH',
            help='Plain-text file with one ingredient name per line.',
        )
        source.add_argument(
            '--names',
            nargs='+',
            metavar='NAME',
            help='One or more ingredient names.',
        )
        source.add_argument(
            '--from-db',
            action='store_true',
            help='Import names from existing Ingredient rows in the database.',
        )
        parser.add_argument(
            '--delay',
            type=float,
            default=0.5,
            metavar='SECONDS',
            help='Delay between USDA API calls in seconds (default: 0.5).',
        )
        parser.add_argument(
            '--skip-existing',
            action='store_true',
            help='Skip ingredient names that already have a NutritionData record.',
        )

    def handle(self, *args, **options):
        client = USDAClient()
        delay = options['delay']
        skip_existing = options['skip_existing']

        names = self._collect_names(options)
        if not names:
            raise CommandError("No ingredient names found to import.")

        self.stdout.write(f"Importing {len(names)} ingredient name(s) from USDA…")
        created = skipped = failed = already_had = 0

        for raw_name in names:
            search_name = _clean_for_usda(raw_name)
            if not search_name:
                self.stdout.write(self.style.WARNING(f"  skipping empty name: '{raw_name}'"))
                skipped += 1
                continue

            if skip_existing:
                if NutritionData.objects.filter(normalized_name=search_name.lower()).exists():
                    already_had += 1
                    continue

            self.stdout.write(f"  → {search_name!r}")
            try:
                usda_result = client.search_food(search_name)
            except Exception as exc:
                self.stdout.write(self.style.ERROR(f"    USDA error: {exc}"))
                failed += 1
                time.sleep(delay)
                continue

            if usda_result:
                usda_description = usda_result.get('description', search_name)
                obj, was_created = NutritionData.objects.get_or_create(
                    name=usda_description,
                    defaults={
                        'normalized_name': search_name.lower(),
                        'calories_per_100g': usda_result.get('calories', 0),
                        'protein_per_100g': usda_result.get('protein', 0),
                        'fat_per_100g': usda_result.get('fat', 0),
                        'carbs_per_100g': usda_result.get('carbs', 0),
                        'fiber_per_100g': usda_result.get('fiber', 0),
                        'sugar_per_100g': usda_result.get('sugar', 0),
                        'usda_fdc_id': str(usda_result.get('fdcId', '')) if usda_result.get('fdcId') else None,
                    },
                )
                status_str = 'created' if was_created else 'exists'
                cal = obj.calories_per_100g
                self.stdout.write(f"    [{status_str}] {obj.name} — {cal:.0f} kcal/100g")
                created += was_created
            else:
                self.stdout.write(self.style.WARNING(f"    no USDA result found"))
                failed += 1

            time.sleep(delay)

        self.stdout.write(
            self.style.SUCCESS(
                f"\nDone. Created: {created}, Already existed (kept): {already_had}, "
                f"No result / error: {failed}, Skipped blank: {skipped}"
            )
        )

    # ------------------------------------------------------------------
    def _collect_names(self, options) -> list[str]:
        if options.get('names'):
            return [n.strip() for n in options['names'] if n.strip()]

        if options.get('file'):
            path = options['file']
            try:
                with open(path, encoding='utf-8') as fh:
                    return [line.strip() for line in fh if line.strip()]
            except OSError as exc:
                raise CommandError(f"Cannot read file '{path}': {exc}") from exc

        if options.get('from_db'):
            # Gather USDA names first, then fall back to ingredient names
            names = set()
            for row in Ingredient.objects.exclude(usda_name='').exclude(usda_name__isnull=True).values_list('usda_name', flat=True):
                names.add(row.strip())
            for row in Ingredient.objects.exclude(name='').exclude(name__isnull=True).values_list('name', flat=True):
                names.add(row.strip())
            return sorted(names)

        return []
