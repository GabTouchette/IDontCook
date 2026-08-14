from django.core.management.base import BaseCommand

from recipes.models import Recipe
from recommendations.api import _fit_and_persist_vectorizer, get_active_vectorizer, store_recipe_vector


class Command(BaseCommand):
    help = (
        "Refit the shared TF-IDF vectorizer over the full recipe corpus (unless "
        "--no-refit is passed) and recompute every recipe's precomputed vector "
        "(recommendations.models.RecipeVector) against it."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            '--no-refit',
            action='store_true',
            help="Reuse the currently active vectorizer artifact instead of refitting from scratch.",
        )

    def handle(self, *args, **options):
        if options['no_refit']:
            tfidf, version = get_active_vectorizer()
        else:
            tfidf, version = _fit_and_persist_vectorizer()

        if tfidf is None:
            self.stdout.write(self.style.WARNING("No recipes found — nothing to vectorize."))
            return

        recipes = Recipe.objects.all()
        total = recipes.count()
        count = 0
        for recipe in recipes.iterator():
            store_recipe_vector(recipe, tfidf, version)
            count += 1
            if count % 200 == 0:
                self.stdout.write(f"  ...{count}/{total} recipes vectorized")

        self.stdout.write(self.style.SUCCESS(
            f"Rebuilt {count} recipe vectors at vectorizer version {version}"
        ))
