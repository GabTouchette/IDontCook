from django.urls import path
from recipes.views import (
    RecipeListAPIView,
    RecipeDetailAPIView,
    RecipeImageUploadAPIView,
    FilteredRecommendationsAPIView,
    RecipeTagsAPIView,
    CanonicalIngredientAutocompleteAPIView,
    RecipeNutritionAPIView,
)

urlpatterns = [
    path("", RecipeListAPIView.as_view(), name="recipe-list"),
    path("<int:pk>/", RecipeDetailAPIView.as_view(), name="recipe-detail"),
    path("<int:pk>/nutrition/", RecipeNutritionAPIView.as_view(), name="recipe-nutrition"),
    path("<int:recipe_id>/image", RecipeImageUploadAPIView.as_view(), name="recipe-image"),
    path('global/filter/', FilteredRecommendationsAPIView.as_view(), name='filtered-recommendations'),
    path('tags/', RecipeTagsAPIView.as_view(), name='recipe-tags'),
    path('ingredients/autocomplete/', CanonicalIngredientAutocompleteAPIView.as_view(), name='canonical-ingredients-autocomplete'),
]
