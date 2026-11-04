"""Resolve existing Ingredient rows to canonical concepts.

Replaces the old ``backfill_ingredient_normalization`` + ``link_ingredients_to_canonical``
commands: the catalog resolver (``recipes.ingredient_resolver``) now owns
normalization, alias/synonym handling, and fuzzy matching in one place, so a
single pass links each ingredient to its :class:`CanonicalIngredient` and records
the method + confidence. Preparation is still backfilled opportunistically since
it remains a stored field.

    # deterministic, fast — string matching only
    python manage.py backfill_ingredient_resolution

    # also let Claude disambiguate the ambiguous middle tier (slower, costs tokens)
    python manage.py backfill_ingredient_resolution --use-llm

    # only (re)touch rows that still have no canonical link
    python manage.py backfill_ingredient_resolution --only-unlinked
"""

from django.core.management.base import BaseCommand
from django.db import transaction

from recipes.models import Ingredient
from recipes import ingredient_resolver
from recipes.ingredient_normalizer import normalize_name_and_prep


class Command(BaseCommand):
    help = "Link Ingredient rows to CanonicalIngredient via the catalog resolver."

    def add_arguments(self, parser):
        parser.add_argument("--batch-size", type=int, default=500,
                            help="Rows to update per bulk_update batch")
        parser.add_argument("--dry-run", action="store_true", help="Don't save changes")
        parser.add_argument("--use-llm", action="store_true",
                            help="Allow the resolver's Claude disambiguation fallback")
        parser.add_argument("--only-unlinked", action="store_true",
                            help="Skip rows that already have a canonical link")
        parser.add_argument("--min-confidence", type=float, default=0.0,
                            help="Only persist links at/above this confidence")

    def handle(self, *args, **options):
        batch_size = options["batch_size"]
        dry_run = options["dry_run"]
        use_llm = options["use_llm"]
        only_unlinked = options["only_unlinked"]
        min_conf = options["min_confidence"]

        ingredient_resolver.clear_cache()  # resolve against the current catalog

        qs = Ingredient.objects.all().order_by("id")
        if only_unlinked:
            qs = qs.filter(canonical__isnull=True)
        total = qs.count()

        self.stdout.write(self.style.NOTICE(
            f"Resolving {total} ingredients (use_llm={use_llm}, "
            f"only_unlinked={only_unlinked}, dry_run={dry_run})"
        ))

        linked = prep_set = scanned = 0
        dirty = []
        method_counts = {}

        for ing in qs.iterator(chunk_size=batch_size):
            scanned += 1
            name = (ing.name or "").strip()
            if not name:
                continue

            changed = False
            res = ingredient_resolver.resolve(name, use_llm=use_llm)
            if res.matched and res.confidence >= min_conf:
                if (ing.canonical_id != res.canonical_id
                        or ing.resolution_method != res.method):
                    ing.canonical_id = res.canonical_id
                    ing.canonical_confidence = res.confidence
                    ing.resolution_method = res.method
                    changed = True
                    linked += 1
                    method_counts[res.method] = method_counts.get(res.method, 0) + 1

            # Opportunistically fill in a missing preparation.
            if not (ing.preparation or "").strip():
                _norm, prep = normalize_name_and_prep(name)
                if prep:
                    ing.preparation = prep
                    changed = True
                    prep_set += 1

            if changed:
                dirty.append(ing)

            if len(dirty) >= batch_size:
                self._flush(dirty, dry_run)
                dirty = []
                self.stdout.write(f"  …scanned {scanned}/{total}, linked {linked}")

        self._flush(dirty, dry_run)

        self.stdout.write(self.style.SUCCESS(
            f"Done. Scanned {scanned}, linked {linked}, preparation set {prep_set}. "
            f"By method: {method_counts or '{}'}" + (" (dry run)" if dry_run else "")
        ))

    @staticmethod
    def _flush(rows, dry_run):
        if not rows or dry_run:
            return
        with transaction.atomic():
            Ingredient.objects.bulk_update(
                rows,
                ["canonical", "canonical_confidence", "resolution_method", "preparation"],
            )
