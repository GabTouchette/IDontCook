import logging

from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from recipes.models import Recipe

from .aggregator import aggregate_ingredients
from .models import GroceryBag, GroceryBagRecipe, GroceryItemOverride
from .serializers import GroceryBagRecipeSerializer
from .sorting import prepare_lines

logger = logging.getLogger(__name__)


def _get_or_create_bag(user):
    bag, _ = GroceryBag.objects.get_or_create(user=user)
    return bag


def _bag_recipes(bag):
    return list(
        bag.bag_recipes.select_related("recipe").prefetch_related(
            "recipe__ingredients__canonical"
        )
    )


def _serialize_bag(bag):
    """Full bag payload: queued recipes + the derived, override-applied list."""
    bag_recipes = _bag_recipes(bag)
    lines = aggregate_ingredients([(br.recipe, br.servings) for br in bag_recipes])

    # Staple ordering + always-hidden set (C1): least-likely-to-have first,
    # salt/pepper/water dropped (surfaced via hidden_count).
    visible, hidden_count = prepare_lines(lines)

    overrides = {o.item_key: o.state for o in bag.overrides.all()}
    items = []
    removed_count = 0
    for line in visible:
        state = overrides.get(line.key)
        if state == GroceryItemOverride.REMOVED:
            removed_count += 1
            continue
        d = line.to_dict()
        d["checked"] = state == GroceryItemOverride.CHECKED
        items.append(d)

    return {
        "recipes": GroceryBagRecipeSerializer(bag_recipes, many=True).data,
        "items": items,
        "removed_count": removed_count,
        "hidden_count": hidden_count,
    }


def _parse_servings(value, default):
    if value is None:
        value = default
    try:
        return max(1, int(value))
    except (TypeError, ValueError):
        return None


class GroceryBagView(APIView):
    """GET the full bag; DELETE to empty it."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(_serialize_bag(_get_or_create_bag(request.user)))

    def delete(self, request):
        bag = _get_or_create_bag(request.user)
        bag.bag_recipes.all().delete()
        bag.overrides.all().delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class GroceryBagRecipesView(APIView):
    """POST to add (or re-set servings of) a recipe in the bag."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        bag = _get_or_create_bag(request.user)
        recipe_id = request.data.get("recipe_id")
        if not recipe_id:
            return Response({"detail": "recipe_id is required."}, status=status.HTTP_400_BAD_REQUEST)
        recipe = get_object_or_404(Recipe, pk=recipe_id)

        servings = _parse_servings(request.data.get("servings"), recipe.servings or 1)
        if servings is None:
            return Response({"detail": "servings must be a positive integer."},
                            status=status.HTTP_400_BAD_REQUEST)

        br, created = GroceryBagRecipe.objects.update_or_create(
            bag=bag, recipe=recipe, defaults={"servings": servings}
        )
        return Response(
            GroceryBagRecipeSerializer(br).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class GroceryBagRecipeDetailView(APIView):
    """PATCH servings; DELETE to remove a recipe from the bag."""
    permission_classes = [IsAuthenticated]

    def _get(self, request, pk):
        bag = _get_or_create_bag(request.user)
        return get_object_or_404(GroceryBagRecipe, pk=pk, bag=bag)

    def patch(self, request, pk):
        br = self._get(request, pk)
        servings = _parse_servings(request.data.get("servings"), None)
        if servings is None:
            return Response({"detail": "servings must be a positive integer."},
                            status=status.HTTP_400_BAD_REQUEST)
        br.servings = servings
        br.save(update_fields=["servings"])
        return Response(GroceryBagRecipeSerializer(br).data)

    def delete(self, request, pk):
        self._get(request, pk).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class GroceryBagItemsView(APIView):
    """POST to upsert a per-item override.

    Body: ``{"key": "<line key>", "state": "removed"|"checked"|null}``. The key
    is the aggregator's stable line key (echoed in each item's ``key`` field). A
    null/absent state clears the override. Returns the refreshed bag.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        bag = _get_or_create_bag(request.user)
        key = request.data.get("key")
        if not key:
            return Response({"detail": "key is required."}, status=status.HTTP_400_BAD_REQUEST)

        state = request.data.get("state")
        if state in (None, "", "clear"):
            bag.overrides.filter(item_key=key).delete()
        elif state in (GroceryItemOverride.REMOVED, GroceryItemOverride.CHECKED):
            GroceryItemOverride.objects.update_or_create(
                bag=bag, item_key=key, defaults={"state": state}
            )
        else:
            return Response({"detail": "state must be 'removed', 'checked', or null."},
                            status=status.HTTP_400_BAD_REQUEST)

        return Response(_serialize_bag(bag))
