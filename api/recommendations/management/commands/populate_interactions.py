from django.core.management.base import BaseCommand
from recommendations.models import UserRecipeInteraction
from social.models import Like, Comment, Vote
from recipes.models import Recipe

class Command(BaseCommand):
    help = 'Populate UserRecipeInteraction data from existing models'

    def handle(self, *args, **kwargs):
        for like in Like.objects.all():
            UserRecipeInteraction.objects.get_or_create(
                user=like.user,
                recipe=like.post.recipe,
                interaction_type='like',
            )

        for comment in Comment.objects.all():
            UserRecipeInteraction.objects.get_or_create(
                user=comment.user,
                recipe=comment.post.recipe,
                interaction_type='comment',
            )

        for vote in Vote.objects.all():
            interaction_type = 'upvote' if vote.value == 1 else 'downvote'
            UserRecipeInteraction.objects.get_or_create(
                user=vote.user,
                recipe=vote.post.recipe,
                interaction_type=interaction_type,
            )

        for recipe in Recipe.objects.filter(parent__isnull=False):
            UserRecipeInteraction.objects.get_or_create(
                user=recipe.created_by,
                recipe=recipe.parent,
                interaction_type='save',
            )

        self.stdout.write(self.style.SUCCESS('Successfully populated interactions'))
