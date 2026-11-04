"""Backfill a real serving count onto recipes that have none.

Nutrition is stored per-serving (``total / servings``), but recipes with a NULL
or <1 ``servings`` were divided by 1 — so the stored macros are the *whole-recipe
total* yet get shown as a single serving (e.g. a 4-serving dish reading 3800 cal
"per serving"). ``Recipe.save()`` now fills servings on new recipes; this command
fixes the existing rows.

For each affected recipe it:
  1. derives servings from ``recipe_yield`` (e.g. "Serves 6"), else DEFAULT_SERVINGS;
  2. if nutrition was already calculated, divides the stored macros by that count
     — exact, because the old divisor was 1 (no USDA/LLM re-run needed).

Writes via queryset ``.update()`` so no save() side effects (meal-type
prediction, full_clean) or id churn touch these rows.

    # See what would change, without writing:
    python manage.py backfill_recipe_servings --dry-run

    # Apply:
    python manage.py backfill_recipe_servings
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Q

from recipes.models import Recipe


class Command(BaseCommand):
    help = "Fill servings (from recipe_yield or default) on recipes missing it, and un-inflate their per-serving nutrition."

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run', action='store_true',
            help='Report what would change without writing to the database.',
        )
        parser.add_argument(
            '--sample', type=int, default=25,
            help='How many example changes to print (default 25).',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        sample = options['sample']

        targets = Recipe.objects.filter(
            Q(servings__isnull=True) | Q(servings__lt=1)
        )
        total = targets.count()
        self.stdout.write(f"Recipes with servings null/<1: {total}")
        if total == 0:
            self.stdout.write(self.style.SUCCESS("Nothing to backfill."))
            return

        from_yield = 0
        from_default = 0
        nutrition_rescaled = 0
        printed = 0

        with transaction.atomic():
            for recipe in targets.iterator():
                parsed = Recipe.parse_servings_from_yield(recipe.recipe_yield)
                servings = parsed or Recipe.DEFAULT_SERVINGS
                if parsed:
                    from_yield += 1
                else:
                    from_default += 1

                fields = {'servings': servings}

                # Stored macros were whole-recipe totals (old divisor == 1); divide
                # down to per-serving. Only meaningful when nutrition exists.
                rescaled = False
                if recipe.is_nutrition_calculated and servings > 1:
                    for macro in ('calories', 'protein', 'fat', 'carbs'):
                        value = getattr(recipe, macro)
                        if value is not None:
                            fields[macro] = round(value / servings, 1)
                            rescaled = True
                if rescaled:
                    nutrition_rescaled += 1

                if printed < sample:
                    src = 'yield' if parsed else 'default'
                    cal_note = ''
                    if rescaled and recipe.calories is not None:
                        cal_note = f", {recipe.calories:.0f}→{fields.get('calories')} cal"
                    self.stdout.write(
                        f"  [{recipe.id}] {str(recipe.title)[:48]!r}: "
                        f"servings→{servings} ({src}, yield={recipe.recipe_yield!r}){cal_note}"
                    )
                    printed += 1

                if not dry_run:
                    Recipe.objects.filter(pk=recipe.pk).update(**fields)

            if dry_run:
                transaction.set_rollback(True)

        verb = "Would set" if dry_run else "Set"
        self.stdout.write("")
        self.stdout.write(
            f"{verb} servings on {total} recipes "
            f"(from recipe_yield: {from_yield}, default={Recipe.DEFAULT_SERVINGS}: {from_default}); "
            f"rescaled nutrition on {nutrition_rescaled}."
        )
        if dry_run:
            self.stdout.write(self.style.WARNING("Dry run — no changes written."))
        else:
            self.stdout.write(self.style.SUCCESS("Done."))
