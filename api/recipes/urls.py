from django.urls import path
from recipes.views import (
    RecipeListAPIView,
    RecipeDetailAPIView,
    RecipeImageUploadAPIView,
    FilteredRecommendationsAPIView,
    RecipeTagsAPIView,
)
from recipes.test_nutrition import test_nutrition_parsing, test_recipe_creation

urlpatterns = [
    path("", RecipeListAPIView.as_view(), name="recipe-list"),
    path("<int:pk>/", RecipeDetailAPIView.as_view(), name="recipe-detail"),
    path("<int:recipe_id>/image", RecipeImageUploadAPIView.as_view(), name="recipe-image"),
    path('global/filter/', FilteredRecommendationsAPIView.as_view(), name='filtered-recommendations'),
    path('tags/', RecipeTagsAPIView.as_view(), name='recipe-tags'),
    path('test-nutrition/', test_nutrition_parsing, name='test-nutrition'),
    path('test-recipe/', test_recipe_creation, name='test-recipe'),
]
