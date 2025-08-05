from django.core.management.base import BaseCommand
from recipes.models import Recipe
from recipes.tasks import format_recipe_ingredients


class Command(BaseCommand):
    help = 'Test the format_recipe_ingredients task'

    def add_arguments(self, parser):
        parser.add_argument('recipe_id', type=int, help='Recipe ID to format')
        parser.add_argument(
            '--async', 
            action='store_true', 
            help='Run as async Celery task'
        )

    def handle(self, *args, **options):
        recipe_id = options['recipe_id']
        
        try:
            recipe = Recipe.objects.get(id=recipe_id)
            self.stdout.write(f"Found recipe: '{recipe.title}' (is_formatted: {recipe.is_formatted})")
        except Recipe.DoesNotExist:
            self.stdout.write(self.style.ERROR(f'Recipe with ID {recipe_id} does not exist'))
            return

        if options['async']:
            self.stdout.write('Running as async Celery task...')
            try:
                task = format_recipe_ingredients.delay(recipe_id)
                self.stdout.write(self.style.SUCCESS(f'Task dispatched with ID: {task.id}'))
                self.stdout.write('Check Celery logs for task execution details')
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Failed to dispatch Celery task: {e}'))
        else:
            self.stdout.write('Running synchronously...')
            try:
                result = format_recipe_ingredients(recipe_id)
                self.stdout.write(self.style.SUCCESS(f'Task completed: {result}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Task failed: {e}'))