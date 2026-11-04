from django.urls import path

from .views import (
    GroceryBagItemsView,
    GroceryBagRecipeDetailView,
    GroceryBagRecipesView,
    GroceryBagView,
)

urlpatterns = [
    path("bag/", GroceryBagView.as_view(), name="grocery-bag"),
    path("bag/recipes/", GroceryBagRecipesView.as_view(), name="grocery-bag-recipes"),
    path("bag/recipes/<int:pk>/", GroceryBagRecipeDetailView.as_view(), name="grocery-bag-recipe-detail"),
    path("bag/items/", GroceryBagItemsView.as_view(), name="grocery-bag-items"),
]
