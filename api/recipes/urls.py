from django.urls import path
from recipes.views import RecipeListCreateAPIView, RecipeDetailAPIView, IngredientListCreateAPIView, IngredientDetailAPIView

urlpatterns = [
    path("recipes/", RecipeListCreateAPIView.as_view(), name="recipe-list-create"),
    path("recipes/<int:pk>/", RecipeDetailAPIView.as_view(), name="recipe-detail"),

    path("ingredients/", IngredientListCreateAPIView.as_view(), name="ingredient-list-create"),
    path("ingredients/<int:pk>/", IngredientDetailAPIView.as_view(), name="ingredient-detail"),
]
