from django.urls import path
from recipes.views import RecipeListAPIView, RecipeDetailAPIView, RecipeImageUploadAPIView, GlobalFilteredRecipesView

urlpatterns = [
    path("", RecipeListAPIView.as_view(), name="recipe-list"),
    path("<int:pk>/", RecipeDetailAPIView.as_view(), name="recipe-detail"),
    path("<int:recipe_id>/image", RecipeImageUploadAPIView.as_view(), name="recipe-image"),
    path('global/filter/', GlobalFilteredRecipesView.as_view(), name='global-filtered-recipes'),
]
