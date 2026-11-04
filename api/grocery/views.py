import logging

from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from django.db.models import Q

from recipes.models import CanonicalIngredient, Recipe

from .aggregator import (
    NEEDS_CONFIRMATION_THRESHOLD,
    aggregate_ingredients,
    line_key_for_ingredient,
)
from .models import (
    GroceryBag,
    GroceryBagRecipe,
    GroceryItemOverride,
    UserPantryItem,
)
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


def _lang(request):
    """Display language for ingredient names: 'fr' or 'en' (default).

    Read from a ``lang`` query param, falling back to a ``lang`` field in the
    request body (POSTs that return the bag).
    """
    raw = (request.query_params.get("lang") or "").strip().lower()
    if not raw and isinstance(getattr(request, "data", None), dict):
        raw = str(request.data.get("lang") or "").strip().lower()
    return "fr" if raw.startswith("fr") else "en"


def _serialize_bag(bag, lang="en"):
    """Full bag payload: queued recipes + the derived, override-applied list."""
    bag_recipes = _bag_recipes(bag)
    lines = aggregate_ingredients(
        [(br.recipe, br.servings) for br in bag_recipes], lang=lang)

    # Staple ordering + always-hidden set (C1), with pantry items forced to the
    # bottom (C2): least-likely-to-have first, salt/pepper/water split off.
    pantry_keys = set(
        bag.user.pantry_items.values_list("item_key", flat=True)
    )
    visible, hidden = prepare_lines(lines, pantry_keys)

    overrides = {o.item_key: o.state for o in bag.overrides.all()}
    removed_count = 0

    def _serialize(line):
        d = line.to_dict()
        state = overrides.get(line.key)
        d["checked"] = state == GroceryItemOverride.CHECKED
        d["in_pantry"] = line.key in pantry_keys
        return d, state

    items = []
    for line in visible:
        d, state = _serialize(line)
        if state == GroceryItemOverride.REMOVED:
            removed_count += 1
            continue
        items.append(d)

    hidden_items = []
    for line in hidden:
        d, state = _serialize(line)
        if state == GroceryItemOverride.REMOVED:
            continue
        hidden_items.append(d)

    return {
        "recipes": GroceryBagRecipeSerializer(bag_recipes, many=True).data,
        "items": items,
        "hidden_items": hidden_items,
        "removed_count": removed_count,
        "hidden_count": len(hidden_items),
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
        return Response(
            _serialize_bag(_get_or_create_bag(request.user), _lang(request)))

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

        return Response(_serialize_bag(bag, _lang(request)))


class GroceryPantryView(APIView):
    """POST to toggle a concept in the user's pantry ("I always have this").

    Body: ``{"key": "<line key>", "in_pantry": true|false}``. Pantry items are
    forced to the bottom of every bag (C2). Returns the refreshed bag.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        bag = _get_or_create_bag(request.user)
        key = request.data.get("key")
        if not key:
            return Response({"detail": "key is required."}, status=status.HTTP_400_BAD_REQUEST)

        in_pantry = request.data.get("in_pantry", True)
        if in_pantry:
            UserPantryItem.objects.get_or_create(user=request.user, item_key=key)
        else:
            UserPantryItem.objects.filter(user=request.user, item_key=key).delete()

        return Response(_serialize_bag(bag, _lang(request)))


class GroceryResolveSearchView(APIView):
    """GET canonical-ingredient search for the confirm picker (§5.3). ``?q=``."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        q = (request.query_params.get("q") or "").strip()
        if len(q) < 2:
            return Response({"results": []})
        matches = CanonicalIngredient.objects.filter(
            Q(canonical_name_en__icontains=q) | Q(canonical_name_fr__icontains=q)
        ).order_by("canonical_name_en")[:20]
        return Response({
            "results": [
                {"concept_id": c.id, "name": c.canonical_name_en, "category": c.category}
                for c in matches
            ]
        })


class GroceryResolveView(APIView):
    """POST to link a needs-confirmation line to a canonical concept (§5.3).

    Body: ``{"key": "<line key>", "concept_id": <id>}``. Writes the chosen
    canonical back onto the matching ingredient rows in the bag's recipes
    (``resolution_method="user"``), only filling/raising confidence — never
    overwriting an already high-confidence match. Returns the refreshed bag.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        bag = _get_or_create_bag(request.user)
        key = request.data.get("key")
        concept_id = request.data.get("concept_id")
        if not key or not concept_id:
            return Response({"detail": "key and concept_id are required."},
                            status=status.HTTP_400_BAD_REQUEST)
        concept = get_object_or_404(CanonicalIngredient, pk=concept_id)

        updated = 0
        for br in _bag_recipes(bag):
            for ing in br.recipe.ingredients.all():
                if line_key_for_ingredient(ing) != key:
                    continue
                conf = ing.canonical_confidence
                # Only fill/raise: skip rows already confidently resolved.
                if ing.canonical_id is not None and conf is not None \
                        and conf >= NEEDS_CONFIRMATION_THRESHOLD:
                    continue
                ing.canonical = concept
                ing.canonical_confidence = 1.0
                ing.resolution_method = "user"
                ing.save(update_fields=[
                    "canonical", "canonical_confidence", "resolution_method"])
                updated += 1

        return Response({**_serialize_bag(bag, _lang(request)), "updated": updated})
