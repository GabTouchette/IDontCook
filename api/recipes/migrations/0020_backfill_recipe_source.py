# Data migration for docs/plans/catalog-first-pivot.md §1.4 (WS-P1).
#
# Backfills Recipe.source for rows that existed before the field was added.
# Verified distribution at authoring time (2026-07-19): of 3,135 recipes,
# 3,125 are owned by three importer accounts —
#   bbc_good_food_importer (1,162), allrecipes_importer (1,000),
#   recipe_scraper (963) — and should become source="catalog". The remaining
# ~10 rows are owned by real users (gab, gabriel_touc_ul11) and are left as
# source="user" (the field default already covers them; matched explicitly
# below purely for clarity/idempotency).
#
# This migration matches by created_by__username against the exact importer
# usernames rather than any proxy (is_superuser, etc.) since none of those
# are reliable signals in this dataset. It does not assume the usernames
# still exist — an empty match for any of them is a no-op, not an error.

from django.db import migrations

CATALOG_IMPORTER_USERNAMES = [
    "bbc_good_food_importer",
    "allrecipes_importer",
    "recipe_scraper",
]


def backfill_source(apps, schema_editor):
    Recipe = apps.get_model("recipes", "Recipe")

    # Importer-owned recipes -> catalog.
    Recipe.objects.filter(
        created_by__username__in=CATALOG_IMPORTER_USERNAMES
    ).update(source="catalog")

    # Everything else (real user-owned recipes, or orphaned rows with no
    # created_by) stays/becomes "user" — matches the field default, applied
    # explicitly here so the migration is a complete, self-contained backfill
    # rather than relying on the default for correctness.
    Recipe.objects.exclude(
        created_by__username__in=CATALOG_IMPORTER_USERNAMES
    ).update(source="user")


def noop_reverse(apps, schema_editor):
    # Not reversible in a meaningful way — the pre-migration state had no
    # `source` distinction to restore. Leave rows as-is on reverse.
    pass


class Migration(migrations.Migration):

    dependencies = [
        ("recipes", "0019_add_recipe_source"),
    ]

    operations = [
        migrations.RunPython(backfill_source, noop_reverse),
    ]
