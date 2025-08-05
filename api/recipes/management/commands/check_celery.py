from django.core.management.base import BaseCommand
from celery import current_app
from recipes.tasks import format_recipe_ingredients


class Command(BaseCommand):
    help = 'Check Celery status and configuration'

    def handle(self, *args, **options):
        self.stdout.write('=== Celery Status Check ===')
        
        # Check if Celery is configured
        try:
            self.stdout.write(f'Celery app: {current_app}')
            self.stdout.write(f'Broker URL: {current_app.conf.broker_url}')
            self.stdout.write(f'Result backend: {current_app.conf.result_backend}')
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Celery configuration error: {e}'))
            return

        # Check registered tasks
        try:
            registered_tasks = list(current_app.tasks.keys())
            self.stdout.write(f'Registered tasks ({len(registered_tasks)}):')
            for task in sorted(registered_tasks):
                if 'format_recipe_ingredients' in task:
                    self.stdout.write(self.style.SUCCESS(f'  ✅ {task}'))
                else:
                    self.stdout.write(f'  - {task}')
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Failed to get registered tasks: {e}'))

        # Try to inspect workers
        try:
            inspect = current_app.control.inspect()
            active_workers = inspect.active()
            
            if active_workers:
                self.stdout.write(self.style.SUCCESS(f'Active workers: {list(active_workers.keys())}'))
                
                # Check if our task is available
                registered = inspect.registered()
                if registered:
                    for worker, tasks in registered.items():
                        if any('format_recipe_ingredients' in task for task in tasks):
                            self.stdout.write(self.style.SUCCESS(f'  ✅ Worker {worker} has format_recipe_ingredients'))
                        else:
                            self.stdout.write(self.style.WARNING(f'  ⚠️ Worker {worker} missing format_recipe_ingredients'))
            else:
                self.stdout.write(self.style.WARNING('No active Celery workers found'))
                self.stdout.write('Start workers with: celery -A api worker --loglevel=info')
                
        except Exception as e:
            self.stdout.write(self.style.WARNING(f'Could not inspect workers: {e}'))
            self.stdout.write('This might indicate Celery workers are not running')

        self.stdout.write('\n=== Recommendations ===')
        self.stdout.write('1. Make sure Redis/RabbitMQ broker is running')
        self.stdout.write('2. Start Celery worker: celery -A api worker --loglevel=info')
        self.stdout.write('3. Test with: python manage.py test_format_ingredients <recipe_id>')
        self.stdout.write('4. Monitor logs in both Django and Celery terminals')