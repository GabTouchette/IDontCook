from django.urls import path

from .views import (
    GroceryBagItemsView,
    GroceryBagRecipeDetailView,
    GroceryBagRecipesView,
    GroceryBagView,
    GroceryPantryView,
    GroceryResolveSearchView,
    GroceryResolveView,
)

urlpatterns = [
    path("bag/", GroceryBagView.as_view(), name="grocery-bag"),
    path("bag/recipes/", GroceryBagRecipesView.as_view(), name="grocery-bag-recipes"),
    path("bag/recipes/<int:pk>/", GroceryBagRecipeDetailView.as_view(), name="grocery-bag-recipe-detail"),
    path("bag/items/", GroceryBagItemsView.as_view(), name="grocery-bag-items"),
    path("bag/resolve/search/", GroceryResolveSearchView.as_view(), name="grocery-resolve-search"),
    path("bag/resolve/", GroceryResolveView.as_view(), name="grocery-resolve"),
    path("pantry/", GroceryPantryView.as_view(), name="grocery-pantry"),
]
