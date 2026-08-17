"""Backfill numeric Ingredient.quantity / unit from preserved text fields.

Bulk-imported catalog recipes had their amounts written only into the combined
``quantity_unit`` / ``original_text`` strings, leaving numeric ``quantity`` NULL.
The API only exposes the numeric fields, so those ingredients rendered as
"1 <ingredient>" in the app and were skipped by nutrition calculation.

This command re-parses the preserved text (``original_text`` preferred, then
``quantity_unit``, then ``name``) with the shared parser and fills in the numeric
fields in place — no re-import, no id churn, no touching user saves/clones.

    # See what would change, with a sample, without writing:
    python manage.py backfill_ingredient_quantities --dry-run --sample 40

    # Apply:
    python manage.py backfill_ingredient_quantities

    # Apply and flag affected recipes for nutrition recalculation:
    python manage.py backfill_ingredient_quantities --reset-nutrition
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Q

from recipes.ingredient_parsing import parse_ingredient
from recipes.models import Ingredient, Recipe


class Command(BaseCommand):
    help = "Backfill numeric Ingredient.quantity/unit from quantity_unit/original_text."

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run', action='store_true',
            help='Report what would change without writing to the database.',
        )
        parser.add_argument(
            '--sample', type=int, default=25,
            help='How many example changes to print (default 25).',
        )
        parser.add_argument(
            '--reset-nutrition', action='store_true',
            help='Flag recipes whose ingredients changed for nutrition recalculation.',
        )
        parser.add_argument(
            '--batch-size', type=int, default=1000,
            help='Rows per bulk_update batch (default 1000).',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        sample_limit = options['sample']
        reset_nutrition = options['reset_nutrition']
        batch_size = options['batch_size']

        # Only rows missing a numeric quantity that still carry recoverable text.
        qs = Ingredient.objects.filter(quantity__isnull=True).filter(
            Q(quantity_unit__isnull=False, quantity_unit__gt='')
            | Q(original_text__isnull=False, original_text__gt='')
            | Q(name__isnull=False, name__gt='')
        )

        total = qs.count()
        self.stdout.write(f"Scanning {total} ingredient rows with NULL quantity …")

        stats = {
            'scanned': 0,
            'quantity_set': 0,
            'unit_set': 0,
            'name_cleaned': 0,
            'prep_set': 0,
            'no_change': 0,
        }
        samples = []
        to_update = []
        changed_ingredient_ids = []
        update_fields = {'quantity', 'unit', 'name', 'preparation'}

        for ing in qs.iterator(chunk_size=2000):
            stats['scanned'] += 1

            # Two independent, SAFE sources:
            #  • quantity_unit ("2 tbsp", "1/2 lb") — the structured amount, clean.
            #  • the existing name — may carry an embedded amount ("4slices orange
            #    cheese"), a leaked metric paren ("(225 g) bacon"), or a trailing
            #    ", preparation". Parsing it only ever strips content already there.
            # original_text is intentionally NOT used as a name source: some rows
            # have corrupt concatenations ("pinch ofsalt") that would clobber a
            # clean name.
            amount = parse_ingredient(ing.quantity_unit or '')
            name_parsed = parse_ingredient(ing.name or '')

            quantity = amount['quantity']
            if quantity is None:
                quantity = name_parsed['quantity']  # old format: number in name
            unit = amount['unit'] or name_parsed['unit']

            changed = False
            before = (ing.quantity, ing.unit, ing.name, ing.preparation)

            if quantity is not None and ing.quantity is None:
                ing.quantity = round(quantity, 4)
                stats['quantity_set'] += 1
                changed = True

            if unit and not (ing.unit or '').strip():
                ing.unit = unit
                stats['unit_set'] += 1
                changed = True

            # Clean the name only from what parsing the name itself yields, and
            # only when it's a non-empty, different value — strips leaked prefixes
            # and embedded numbers without ever introducing foreign text.
            new_name = name_parsed['name']
            if new_name and new_name != (ing.name or ''):
                ing.name = new_name
                stats['name_cleaned'] += 1
                changed = True

            if name_parsed['preparation'] and not (ing.preparation or '').strip():
                ing.preparation = name_parsed['preparation']
                stats['prep_set'] += 1
                changed = True

            if not changed:
                stats['no_change'] += 1
                continue

            if len(samples) < sample_limit:
                samples.append((before, (ing.quantity, ing.unit, ing.name, ing.preparation)))

            to_update.append(ing)
            changed_ingredient_ids.append(ing.id)

            if not dry_run and len(to_update) >= batch_size:
                Ingredient.objects.bulk_update(to_update, list(update_fields))
                to_update.clear()

        if not dry_run and to_update:
            Ingredient.objects.bulk_update(to_update, list(update_fields))
            to_update.clear()

        # --- Report ---
        self.stdout.write("")
        self.stdout.write("Sample of changes (before -> after):")
        for before, after in samples:
            b_q, b_u, b_n, b_p = before
            a_q, a_u, a_n, a_p = after
            self.stdout.write(
                f"  qty {b_q}->{a_q}  unit {b_u!r}->{a_u!r}  "
                f"name {b_n!r}->{a_n!r}  prep {b_p!r}->{a_p!r}"
            )

        self.stdout.write("")
        self.stdout.write(
            f"{'[DRY RUN] ' if dry_run else ''}"
            f"scanned={stats['scanned']} quantity_set={stats['quantity_set']} "
            f"unit_set={stats['unit_set']} name_cleaned={stats['name_cleaned']} "
            f"prep_set={stats['prep_set']} unchanged={stats['no_change']}"
        )

        if reset_nutrition and changed_ingredient_ids and not dry_run:
            recipe_ids = list(
                Recipe.objects.filter(ingredients__id__in=changed_ingredient_ids)
                .values_list('id', flat=True)
                .distinct()
            )
            updated = Recipe.objects.filter(id__in=recipe_ids).update(
                is_nutrition_calculated=False
            )
            self.stdout.write(
                f"Flagged {updated} recipe(s) for nutrition recalculation."
            )
        elif reset_nutrition and dry_run:
            recipe_ids = (
                Recipe.objects.filter(ingredients__id__in=changed_ingredient_ids)
                .values_list('id', flat=True)
                .distinct()
            )
            self.stdout.write(
                f"[DRY RUN] would flag {len(set(recipe_ids))} recipe(s) for "
                f"nutrition recalculation."
            )

        if dry_run:
            self.stdout.write(self.style.WARNING("Dry run — nothing written."))
        else:
            self.stdout.write(self.style.SUCCESS("Backfill complete."))
