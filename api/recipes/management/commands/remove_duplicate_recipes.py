from django.core.management.base import BaseCommand
from django.db.models import Count

from recipes.models import Recipe


class Command(BaseCommand):
    help = 'Remove duplicate recipes by title, keeping the oldest (lowest ID).'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run', action='store_true',
            help='Show what would be deleted without deleting anything',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']

        duplicates = (
            Recipe.objects.values('title')
            .annotate(count=Count('id'))
            .filter(count__gt=1)
            .order_by('-count')
        )

        total_titles = duplicates.count()
        if total_titles == 0:
            self.stdout.write(self.style.SUCCESS('No duplicates found.'))
            return

        self.stdout.write(f"Found {total_titles} duplicate titles …\n")

        total_removed = 0
        for dup in duplicates:
            title = dup['title']
            recipes = Recipe.objects.filter(title=title).order_by('id')
            to_delete = list(recipes[1:])
            if not to_delete:
                continue

            ids = [r.id for r in to_delete]
            self.stdout.write(
                f"  '{title[:60]}' — keeping id={recipes[0].id}, "
                f"{'would delete' if dry_run else 'deleting'} {len(ids)} duplicate(s)"
            )

            if not dry_run:
                Recipe.objects.filter(id__in=ids).delete()

            total_removed += len(ids)

        label = '[DRY RUN] ' if dry_run else ''
        self.stdout.write(
            self.style.SUCCESS(
                f"\n{label}Done — {total_titles} duplicate titles, "
                f"{total_removed} recipes {'would be ' if dry_run else ''}removed"
            )
        )
