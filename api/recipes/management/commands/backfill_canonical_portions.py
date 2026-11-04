"""Populate per-canonical household-unit gram weights from USDA foodPortions.

Path B of the catalog-first pivot: replace the global density/piece-weight
guesses in ``nutrition_service`` with each ingredient's *real* gram weights.
For every ``CanonicalIngredient`` that has a pinned ``usda_fdc_id`` this fetches
the FoodData Central detail record, extracts its ``foodPortions`` (cup, tbsp,
medium, clove, ...) and stores them on ``canonical.portions``, deriving
``density_g_per_ml`` from any volumetric portion.

    python manage.py backfill_canonical_portions --only-missing --sleep 0.2
"""

import time

from django.core.management.base import BaseCommand

from recipes.models import CanonicalIngredient
from recipes.usda_api import USDAClient


class Command(BaseCommand):
    help = "Backfill CanonicalIngredient.portions / density_g_per_ml from USDA foodPortions."

    def add_arguments(self, parser):
        parser.add_argument("--dry-run", action="store_true", help="Don't save changes")
        parser.add_argument("--limit", type=int, default=0, help="Max rows to process (0 = all)")
        parser.add_argument(
            "--only-missing",
            action="store_true",
            help="Skip canonicals that already have portions populated",
        )
        parser.add_argument(
            "--overwrite",
            action="store_true",
            help="Replace existing portions instead of merging into them",
        )
        parser.add_argument(
            "--sleep",
            type=float,
            default=0.2,
            help="Seconds to sleep between USDA requests (rate limiting)",
        )

    @staticmethod
    def _derive_density(portions: dict) -> float | None:
        """g/mL from a volumetric portion, if one is present (cup > tbsp > tsp)."""
        for unit, ml in (("cup", 240.0), ("tbsp", 15.0), ("tsp", 5.0)):
            grams = portions.get(unit)
            if grams:
                density = grams / ml
                # Sanity window: reject implausible densities (bad USDA rows).
                if 0.1 <= density <= 2.0:
                    return round(density, 4)
        return None

    def handle(self, *args, **options):
        dry = options["dry_run"]
        limit = options["limit"]
        only_missing = options["only_missing"]
        overwrite = options["overwrite"]
        sleep_s = options["sleep"]

        client = USDAClient()
        if not client.api_key:
            self.stderr.write(self.style.ERROR("USDA_API_KEY not configured; aborting."))
            return

        qs = CanonicalIngredient.objects.exclude(usda_fdc_id__isnull=True).exclude(
            usda_fdc_id__exact=""
        ).order_by("id")
        if limit:
            qs = qs[:limit]

        scanned = updated = skipped = no_portions = 0

        for ci in qs.iterator():
            scanned += 1
            if only_missing and ci.portions:
                skipped += 1
                continue

            detail = client.get_food_details(str(ci.usda_fdc_id))
            if sleep_s:
                time.sleep(sleep_s)
            if not detail:
                no_portions += 1
                self.stdout.write(f"  ? {ci.canonical_name_en} (fdc {ci.usda_fdc_id}): no detail")
                continue

            portions = USDAClient.parse_food_portions(detail)
            if not portions:
                no_portions += 1
                self.stdout.write(f"  ? {ci.canonical_name_en}: no usable portions")
                continue

            merged = portions if overwrite else {**(ci.portions or {}), **portions}
            density = self._derive_density(merged)

            self.stdout.write(
                f"  + {ci.canonical_name_en}: {merged}"
                + (f" density={density}" if density else "")
            )

            if not dry:
                ci.portions = merged
                fields = ["portions"]
                if density is not None:
                    ci.density_g_per_ml = density
                    fields.append("density_g_per_ml")
                ci.save(update_fields=fields)
            updated += 1

            if scanned % 100 == 0:
                self.stdout.write(f"Scanned {scanned}, updated {updated}")

        self.stdout.write(
            self.style.SUCCESS(
                f"Done. Scanned {scanned}, updated {updated}, "
                f"skipped {skipped}, no-portions {no_portions}"
                + (" (dry run)" if dry else "")
            )
        )
