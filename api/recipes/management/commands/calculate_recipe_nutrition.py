from django.core.management.base import BaseCommand
from django.db import transaction
from recipes.models import Recipe
from recipes.nutrition_service import NutritionService

class Command(BaseCommand):
    help = 'Calculate nutrition data for all recipes'

    def add_arguments(self, parser):
        parser.add_argument(
            '--recipe-id',
            type=int,
            help='Calculate nutrition for specific recipe ID',
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Recalculate even if nutrition data already exists',
        )

    def handle(self, *args, **options):
        service = NutritionService()
        
        if options['recipe_id']:
            # Calculate for specific recipe
            try:
                recipe = Recipe.objects.get(id=options['recipe_id'])
                self.calculate_recipe_nutrition(recipe, service, options['force'])
            except Recipe.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f'Recipe with ID {options["recipe_id"]} not found')
                )
        else:
            # Calculate for all recipes
            recipes = Recipe.objects.all()
            if not options['force']:
                recipes = recipes.filter(calories__isnull=True)
            
            total = recipes.count()
            self.stdout.write(f'Processing {total} recipes...')
            
            for i, recipe in enumerate(recipes, 1):
                self.calculate_recipe_nutrition(recipe, service, options['force'])
                if i % 10 == 0:
                    self.stdout.write(f'Processed {i}/{total} recipes')
        
        self.stdout.write(
            self.style.SUCCESS('Successfully calculated nutrition data')
        )

    def calculate_recipe_nutrition(self, recipe, service, force=False):
        """Calculate nutrition for a single recipe."""
        if not force and recipe.calories is not None:
            self.stdout.write(f'Skipping {recipe.title} (already has nutrition data)')
            return
        
        try:
            with transaction.atomic():
                nutrition = recipe.calculate_nutrition()
                if nutrition and nutrition.get('calories', 0) > 0:
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'✓ {recipe.title}: {nutrition["calories"]:.1f} cal, '
                            f'{nutrition["protein"]:.1f}g protein'
                        )
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(f'⚠ {recipe.title}: No nutrition data found')
                    )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ Error calculating nutrition for {recipe.title}: {e}')
            )