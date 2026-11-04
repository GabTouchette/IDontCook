"""Management command: clean_recipe_tags

Canonicalizes the `tags` on every recipe against the curated vocabulary in
`recipes.tag_vocabulary`: near-miss variants are remapped to their canonical
form and anything off-vocabulary (author bylines, nutrient labels, kcal/time/
serving bands, ingredient names, raw site taxonomy) is dropped.

This is the bulk counterpart to the per-save enforcement in `Recipe.save()`.
It writes tags directly (bulk_update) rather than calling `save()`, so it does
NOT trigger meal-type ML prediction or nutrition recalculation — it only touches
the tag list. Canonical meal types survive untouched, so recipes keep their
meal-type assignment.

USAGE:
    # Preview what would change (no DB writes) — DEFAULT is a real run, so
    # always dry-run against prod first:
    python manage.py clean_recipe_tags --dry-run

    # Apply the cleanup:
    python manage.py clean_recipe_tags

    # Show the full list of dropped tags (with counts) instead of the top 40:
    python manage.py clean_recipe_tags --dry-run --show-all-dropped
"""

from collections import Counter

from django.core.management.base import BaseCommand

from recipes.models import Recipe
from recipes.tag_vocabulary import canonicalize_tags, canonicalize_one


class Command(BaseCommand):
    help = "Canonicalize recipe tags against the curated vocabulary (remap variants, drop junk)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show what would change without writing to the database.",
        )
        parser.add_argument(
            "--batch-size",
            type=int,
            default=500,
            help="Rows per bulk_update batch when applying (default: 500).",
        )
        parser.add_argument(
            "--show-all-dropped",
            action="store_true",
            help="List every dropped tag with its count (default: top 40).",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        batch_size = options["batch_size"]
        show_all_dropped = options["show_all_dropped"]

        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN — no changes will be saved.\n"))

        distinct_before = set()
        distinct_after = set()
        dropped_counter = Counter()
        remapped_counter = Counter()  # (original -> canonical) occurrences
        recipes_changed = 0
        recipes_total = 0
        tags_before_total = 0
        tags_after_total = 0

        to_update = []

        # Only pull id + tags; iterator() keeps memory flat over the full catalog.
        qs = Recipe.objects.all().only("id", "tags").iterator(chunk_size=1000)
        for recipe in qs:
            recipes_total += 1
            original = list(recipe.tags or [])
            tags_before_total += len(original)
            distinct_before.update(str(t) for t in original)

            cleaned = canonicalize_tags(original, enforce_single_meal_type=True)
            tags_after_total += len(cleaned)
            distinct_after.update(cleaned)

            # Attribute each original tag to dropped vs remapped for reporting.
            for t in original:
                canon = canonicalize_one(t)
                if canon is None:
                    dropped_counter[str(t)] += 1
                elif str(t) != canon:
                    remapped_counter[f"{t} -> {canon}"] += 1

            if cleaned != original:
                recipes_changed += 1
                recipe.tags = cleaned
                to_update.append(recipe)

                if len(to_update) >= batch_size and not dry_run:
                    Recipe.objects.bulk_update(to_update, ["tags"])
                    to_update = []

        if not dry_run and to_update:
            Recipe.objects.bulk_update(to_update, ["tags"])

        # ----- Report -----
        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS("=== Tag cleanup summary ==="))
        self.stdout.write(f"Recipes scanned:        {recipes_total}")
        self.stdout.write(f"Recipes changed:        {recipes_changed}")
        self.stdout.write(
            f"Distinct tags:          {len(distinct_before)} -> {len(distinct_after)}"
        )
        self.stdout.write(
            f"Total tag assignments:  {tags_before_total} -> {tags_after_total}"
        )

        if remapped_counter:
            self.stdout.write("")
            self.stdout.write(self.style.MIGRATE_HEADING("Top remaps:"))
            for label, cnt in remapped_counter.most_common(30):
                self.stdout.write(f"  {cnt:6d}  {label}")

        if dropped_counter:
            self.stdout.write("")
            total_dropped = sum(dropped_counter.values())
            self.stdout.write(
                self.style.MIGRATE_HEADING(
                    f"Dropped tags ({len(dropped_counter)} distinct, "
                    f"{total_dropped} assignments):"
                )
            )
            limit = None if show_all_dropped else 40
            for tag, cnt in dropped_counter.most_common(limit):
                self.stdout.write(f"  {cnt:6d}  {tag}")
            if limit is not None and len(dropped_counter) > limit:
                self.stdout.write(
                    f"  … {len(dropped_counter) - limit} more "
                    f"(use --show-all-dropped to list them)"
                )

        self.stdout.write("")
        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN complete — nothing was written."))
        else:
            self.stdout.write(self.style.SUCCESS("Done — tags updated."))
