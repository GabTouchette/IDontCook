from django.db import models
from django.http import JsonResponse
from accounts.models import CustomUser
from recipes.models import Recipe
from rest_framework.pagination import PageNumberPagination
from rest_framework.exceptions import NotFound
from django.core.paginator import Paginator, InvalidPage

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