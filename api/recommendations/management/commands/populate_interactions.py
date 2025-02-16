from django.core.management.base import BaseCommand
from recipes.models import Save
from recommendations.models import UserRecipeInteraction
from social.models import Like, Comment, Vote

class Command(BaseCommand):
    help = 'Populate UserRecipeInteraction data from existing models'

    def handle(self, *args, **kwargs):
        # Populate from Likes
        for like in Like.objects.all():
            UserRecipeInteraction.objects.get_or_create(
                user=like.user,
                recipe=like.post.recipe,
                interaction_type='like',
            )

        # Populate from Comments
        for comment in Comment.objects.all():
            UserRecipeInteraction.objects.get_or_create(
                user=comment.user,
                recipe=comment.post.recipe,
                interaction_type='comment',
            )

        # Populate from Votes
        for vote in Vote.objects.all():
            interaction_type = 'upvote' if vote.value == 1 else 'downvote'
            UserRecipeInteraction.objects.get_or_create(
                user=vote.user,
                recipe=vote.post.recipe,
                interaction_type=interaction_type,
            )

        # Populate from Saves
        for save in Save.objects.all():
            UserRecipeInteraction.objects.get_or_create(
                user=save.user,
                recipe=save.recipe,
                interaction_type='save',
            )

        self.stdout.write(self.style.SUCCESS('Successfully populated interactions'))