from django.urls import path
from recipes.views import RecipeListAPIView, RecipeDetailAPIView, IngredientListAPIView, IngredientDetailAPIView, HasSavedRecipeAPIView

urlpatterns = [
    path("recipes/", RecipeListAPIView.as_view(), name="recipe-list"),
    path("recipes/<int:pk>/", RecipeDetailAPIView.as_view(), name="recipe-detail"),

    path("ingredients/", IngredientListAPIView.as_view(), name="ingredient-list"),
    path("ingredients/<int:pk>/", IngredientDetailAPIView.as_view(), name="ingredient-detail"),

    path('recipes/<int:recipe_id>/is_saved/', HasSavedRecipeAPIView.as_view(), name='has-saved-recipe'),
]
