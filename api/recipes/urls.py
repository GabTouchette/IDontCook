from django.urls import path
from recipes.views import (
    RecipeListAPIView,
    RecipeDetailAPIView,
    RecipeImageUploadAPIView,
    FilteredRecommendationsAPIView,
    RecipeTagsAPIView,
)

urlpatterns = [
    path("", RecipeListAPIView.as_view(), name="recipe-list"),
    path("<int:pk>/", RecipeDetailAPIView.as_view(), name="recipe-detail"),
    path("<int:recipe_id>/image", RecipeImageUploadAPIView.as_view(), name="recipe-image"),
    path('global/filter/', FilteredRecommendationsAPIView.as_view(), name='filtered-recommendations'),
    path('tags/', RecipeTagsAPIView.as_view(), name='recipe-tags'),
]
