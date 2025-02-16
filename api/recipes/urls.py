from django.urls import path
from recipes.views import RecipeListAPIView, RecipeDetailAPIView, HasSavedRecipeAPIView, RecipeImageUploadAPIView

urlpatterns = [
    path("", RecipeListAPIView.as_view(), name="recipe-list"),
    path("<int:pk>/", RecipeDetailAPIView.as_view(), name="recipe-detail"),
    path("<int:recipe_id>/image", RecipeImageUploadAPIView.as_view(), name="recipe-detail"),
    path('<int:recipe_id>/is_saved/', HasSavedRecipeAPIView.as_view(), name='has-saved-recipe'),
]
