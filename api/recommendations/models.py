from django.db import models
from django.http import JsonResponse
from accounts.models import CustomUser
from recipes.models import Recipe
from rest_framework.pagination import PageNumberPagination
from rest_framework.exceptions import NotFound
from django.core.paginator import Paginator, InvalidPage

class VectorizerArtifact(models.Model):
    """
    A fitted TF-IDF vectorizer, persisted so that user-profile vectors and
    per-recipe vectors (RecipeVector) are always computed in the same
    vector space. `version` tags the fitted vocabulary so stale RecipeVector
    rows (from a previous fit) can be detected and ignored/recomputed.
    """
    version = models.CharField(max_length=64, unique=True)
    blob = models.BinaryField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"VectorizerArtifact({self.version})"


class RecipeVector(models.Model):
    """
    Precomputed TF-IDF vector for a recipe, stored sparsely as a list of
    [vocabulary_index, weight] pairs to avoid bloating the DB with mostly-zero
    dense vectors. `vectorizer_version` must match the currently active
    VectorizerArtifact.version for the stored vector to be usable as-is;
    otherwise it's stale and callers should fall back to an on-the-fly
    transform (see recommendations.api.get_similar_recipes).
    """
    recipe = models.OneToOneField(Recipe, on_delete=models.CASCADE, related_name='vector')
    vector = models.JSONField(help_text="Sparse TF-IDF vector as [[index, weight], ...]")
    vectorizer_version = models.CharField(max_length=64, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"RecipeVector(recipe={self.recipe_id}, version={self.vectorizer_version})"


class UserRecipeInteraction(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE)
    interaction_type = models.CharField(max_length=20, choices=[
        ('like', 'Like'),
        ('comment', 'Comment'),
        ('upvote', 'Upvote'),
        ('downvote', 'Downvote'),
    ])
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'recipe', 'interaction_type')

    def __str__(self):
        return f"{self.user.username} {self.interaction_type}d {self.recipe.title}"


class MixedRecommendationPagination(PageNumberPagination):
    page_size = 20
    
    def paginate_queryset(self, queryset, request, view=None):
        page_size = self.get_page_size(request)
        if not page_size:
            return None

        paginator = Paginator(queryset, page_size)
        page_number = self.get_page_number(request, paginator)

        try:
            page = paginator.page(page_number)
        except InvalidPage as exc:
            raise NotFound(f'Invalid page {page_number}: {str(exc)}')

        self.page = page
        self.request = request
        self.count = paginator.count

        return list(page)

    def get_paginated_response(self, data):
        return JsonResponse({
            'count': self.count,
            'next': self.get_next_link(),
            'previous': self.get_previous_link(),
            'results': data
        })