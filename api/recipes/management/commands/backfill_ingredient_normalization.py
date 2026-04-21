from django.core.management.base import BaseCommand
from django.db import transaction
from recipes.models import Ingredient
from recipes.ingredient_normalizer import normalize_name_and_prep


class Command(BaseCommand):
    help = "Backfill Ingredient.normalized_name and preparation using the shared normalizer"

    def add_arguments(self, parser):
        parser.add_argument(
            "--batch-size",
            type=int,
            default=500,
            help="Number of ingredients to process per batch",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Run without saving changes",
        )

    def handle(self, *args, **options):
        batch_size = options["batch_size"]
        dry_run = options["dry_run"]

        qs = Ingredient.objects.all().order_by("id")
        total = qs.count()
        updated = 0

        self.stdout.write(self.style.NOTICE(f"Processing {total} ingredients (batch_size={batch_size}, dry_run={dry_run})"))

        start = 0
        while start < total:
            batch = list(qs[start:start + batch_size])
            start += batch_size

            dirty = []
            for ing in batch:
                original_name = (ing.name or "").strip()
                if not original_name:
                    continue

                normalized, prep = normalize_name_and_prep(original_name)

                changed = False
                if normalized and (ing.normalized_name or "").strip() != normalized:
                    ing.normalized_name = normalized
                    changed = True

                # Only set preparation if it's blank and we extracted one
                if (not (ing.preparation or "").strip()) and prep:
                    ing.preparation = prep
                    changed = True

                # Set a baseline confidence if we touched normalization
                if changed and ing.match_confidence is None:
                    ing.match_confidence = 0.7

                if changed:
                    dirty.append(ing)

            if dirty and not dry_run:
                with transaction.atomic():
                    Ingredient.objects.bulk_update(dirty, ["normalized_name", "preparation", "match_confidence"])
                updated += len(dirty)

            self.stdout.write(self.style.SUCCESS(f"Processed {min(start, total)}/{total}... updated {updated} so far"))

        self.stdout.write(self.style.SUCCESS(f"Done. Updated {updated}/{total} ingredients."))
