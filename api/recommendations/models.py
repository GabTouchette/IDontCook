from django.db import models
from accounts.models import CustomUser
from recipes.models import Recipe

class UserRecipeInteraction(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE)
    interaction_type = models.CharField(max_length=20, choices=[
        ('like', 'Like'),
        ('comment', 'Comment'),
        ('upvote', 'Upvote'),
        ('downvote', 'Downvote'),
        ('save', 'Save'),
    ])
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'recipe', 'interaction_type')

    def __str__(self):
        return f"{self.user.username} {self.interaction_type}d {self.recipe.title}"


class UserRecommendation(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE)
    score = models.FloatField()  # Recommendation score (higher = more relevant)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'recipe')

    def __str__(self):
        return f"Recommendation for {self.user.username}: {self.recipe.title} (Score: {self.score})"