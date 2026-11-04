from django.urls import path
from recipes.views import (
    RecipeListAPIView,
    RecipeDetailAPIView,
    RecipeReformatAPIView,
    RecipeImageUploadAPIView,
    RecipeInteractionAPIView,
    RecipeClickAPIView,
    FilteredRecommendationsAPIView,
    RecipeTagsAPIView,
    RecipeTagVocabularyAPIView,
    CanonicalIngredientAutocompleteAPIView,
    RecipeNutritionAPIView,
)

urlpatterns = [
    path("", RecipeListAPIView.as_view(), name="recipe-list"),
    path("<int:pk>/", RecipeDetailAPIView.as_view(), name="recipe-detail"),
    path("<int:pk>/reformat/", RecipeReformatAPIView.as_view(), name="recipe-reformat"),
    path("<int:pk>/nutrition/", RecipeNutritionAPIView.as_view(), name="recipe-nutrition"),
    path("<int:pk>/interact/", RecipeInteractionAPIView.as_view(), name="recipe-interact"),
    path("<int:pk>/click/", RecipeClickAPIView.as_view(), name="recipe-click"),
    path("<int:recipe_id>/image", RecipeImageUploadAPIView.as_view(), name="recipe-image"),
    path('global/filter/', FilteredRecommendationsAPIView.as_view(), name='filtered-recommendations'),
    path('tags/', RecipeTagsAPIView.as_view(), name='recipe-tags'),
    path('tags/vocabulary/', RecipeTagVocabularyAPIView.as_view(), name='recipe-tag-vocabulary'),
    path('ingredients/autocomplete/', CanonicalIngredientAutocompleteAPIView.as_view(), name='canonical-ingredients-autocomplete'),
]
