"""Tests for grocery.aggregator — the Grocery Bag ingredient aggregation core.

Covers the four behaviors from the Part A build step
(docs/plans/grocery-bag-implementation.md §8):
  (a) same-dimension sums (cloves+cloves, ml+cup)
  (b) bridge folding (grams-of-garlic -> cloves via portions)
  (c) residual components (unconvertible leftovers kept, never dropped)
  (d) multi-recipe provenance

Plus purchase-dimension selection, servings scaling, unresolved/low-confidence
flagging, and the extracted units module staying behavior-compatible.
"""
from __future__ import annotations

from django.contrib.auth import get_user_model
from django.test import TestCase

from recipes.models import CanonicalIngredient, Ingredient, Recipe

from grocery.aggregator import (
    aggregate_ingredients,
    purchase_dimension,
    NEEDS_CONFIRMATION_THRESHOLD,
)
from grocery import units


def _recipe(title, servings=1):
    user, _ = get_user_model().objects.get_or_create(username="grocer")
    return Recipe.objects.create(title=title, servings=servings, created_by=user)


def _ingredient(recipe, name, quantity=None, unit=None, canonical=None,
                confidence=None):
    ing = Ingredient.objects.create(
        name=name, quantity=quantity, unit=unit,
        canonical=canonical, canonical_confidence=confidence,
    )
    recipe.ingredients.add(ing)
    return ing


def _by_name(lines):
    return {line.name: line for line in lines}


class PurchaseDimensionTests(TestCase):
    def test_category_default(self):
        self.assertEqual(purchase_dimension("chicken breast", "MS"), "mass")
        self.assertEqual(purchase_dimension("olive oil", "CO"), "volume")
        self.assertEqual(purchase_dimension("lemon", "PR"), "count")

    def test_name_override_beats_category(self):
        # spinach is Produce (default count) but sold by weight
        self.assertEqual(purchase_dimension("spinach", "PR"), "mass")
        # eggs are Dairy & Eggs (default mass) but sold by count
        self.assertEqual(purchase_dimension("egg", "DE"), "count")
        self.assertEqual(purchase_dimension("milk", "DE"), "volume")

    def test_override_matches_plural_via_normalizer(self):
        # normalizer singularizes "eggs" -> "egg" before override lookup
        self.assertEqual(purchase_dimension("eggs", "DE"), "count")

    def test_unknown_category_falls_back(self):
        self.assertEqual(purchase_dimension("mystery", None), "count")


class SameDimensionSumTests(TestCase):
    """(a) lines in the same dimension combine into one amount."""

    def setUp(self):
        self.garlic = CanonicalIngredient.objects.create(
            canonical_name_en="garlic", category="PR", portions={"clove": 3.0},
        )
        self.milk = CanonicalIngredient.objects.create(
            canonical_name_en="milk", category="DE",
        )

    def test_count_plus_count(self):
        r = _recipe("Garlic Soup")
        _ingredient(r, "garlic", 2, "clove", canonical=self.garlic, confidence=1.0)
        _ingredient(r, "garlic", 3, "cloves", canonical=self.garlic, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r, 1)]))["garlic"]
        self.assertEqual(line.amount.dimension, "count")
        self.assertEqual(line.amount.unit, "clove")
        self.assertEqual(line.amount.value, 5.0)
        self.assertEqual(line.components, [])
        # approx_g uses the portion weight: 5 cloves * 3g
        self.assertEqual(line.approx_g, 15.0)

    def test_volume_folds_cup_into_ml(self):
        r = _recipe("Bechamel")
        _ingredient(r, "milk", 500, "ml", canonical=self.milk, confidence=1.0)
        _ingredient(r, "milk", 1, "cup", canonical=self.milk, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r, 1)]))["milk"]
        self.assertEqual(line.amount.dimension, "volume")
        self.assertEqual(line.amount.unit, "ml")
        self.assertEqual(line.amount.value, 740.0)  # 500 + 240
        self.assertEqual(line.components, [])

    def test_one_row_per_concept_even_with_mixed_units(self):
        # cloves (count) + grams (mass) must NOT become two rows
        r = _recipe("Mixed Garlic")
        _ingredient(r, "garlic", 2, "clove", canonical=self.garlic, confidence=1.0)
        _ingredient(r, "garlic", 30, "g", canonical=self.garlic, confidence=1.0)

        lines = aggregate_ingredients([(r, 1)])
        self.assertEqual(len(lines), 1)


class BridgeFoldingTests(TestCase):
    """(b) a stray-unit line folds into the chosen dimension via portions."""

    def setUp(self):
        self.garlic = CanonicalIngredient.objects.create(
            canonical_name_en="garlic", category="PR", portions={"clove": 3.0},
        )

    def test_grams_fold_into_cloves(self):
        r = _recipe("Aglio e Olio")
        _ingredient(r, "garlic", 4, "clove", canonical=self.garlic, confidence=1.0)
        _ingredient(r, "garlic", 30, "g", canonical=self.garlic, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r, 1)]))["garlic"]
        # 4 cloves + 30g / 3g-per-clove = 4 + 10 = 14 cloves, one amount, no residual
        self.assertEqual(line.amount.unit, "clove")
        self.assertEqual(line.amount.value, 14.0)
        self.assertEqual(line.components, [])


class ResidualComponentTests(TestCase):
    """(c) unconvertible leftovers are kept as components, never dropped."""

    def test_no_portion_leaves_residual(self):
        # garlic with no portion data: grams can't fold into cloves
        garlic = CanonicalIngredient.objects.create(
            canonical_name_en="garlic", category="PR", portions={},
        )
        r = _recipe("Roast")
        _ingredient(r, "garlic", 2, "clove", canonical=garlic, confidence=1.0)
        _ingredient(r, "garlic", 30, "g", canonical=garlic, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r, 1)]))["garlic"]
        self.assertEqual(line.amount.unit, "clove")
        self.assertEqual(line.amount.value, 2.0)
        self.assertEqual(len(line.components), 1)
        self.assertEqual(line.components[0].unit, "g")
        self.assertEqual(line.components[0].quantity, 30.0)

    def test_mass_dimension_keeps_unconvertible_count(self):
        # flour is mass; a "1 pinch" count line has no gram bridge -> residual
        flour = CanonicalIngredient.objects.create(
            canonical_name_en="flour", category="BK", portions={},
        )
        r = _recipe("Bread")
        _ingredient(r, "flour", 500, "g", canonical=flour, confidence=1.0)
        _ingredient(r, "flour", 1, "pinch", canonical=flour, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r, 1)]))["flour"]
        self.assertEqual(line.amount.dimension, "mass")
        self.assertEqual(line.amount.value, 500.0)
        self.assertEqual([(c.quantity, c.unit) for c in line.components], [(1.0, "pinch")])


class ProvenanceAndScalingTests(TestCase):
    """(d) provenance across recipes, plus servings scaling."""

    def setUp(self):
        self.garlic = CanonicalIngredient.objects.create(
            canonical_name_en="garlic", category="PR", portions={"clove": 3.0},
        )

    def test_merges_across_recipes_with_sources(self):
        r1 = _recipe("Butter Chicken")
        r2 = _recipe("Pasta")
        _ingredient(r1, "garlic", 4, "clove", canonical=self.garlic, confidence=1.0)
        _ingredient(r2, "garlic", 3, "clove", canonical=self.garlic, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r1, 1), (r2, 1)]))["garlic"]
        self.assertEqual(line.amount.value, 7.0)
        titles = sorted(s.title for s in line.sources)
        self.assertEqual(titles, ["Butter Chicken", "Pasta"])
        self.assertEqual(len(line.sources), 2)

    def test_servings_scale_quantities_and_sources(self):
        # recipe base 2 servings, asked for 4 -> x2
        r = _recipe("Scaled", servings=2)
        _ingredient(r, "garlic", 2, "clove", canonical=self.garlic, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r, 4)]))["garlic"]
        self.assertEqual(line.amount.value, 4.0)
        self.assertEqual(line.sources[0].quantity, 4.0)


class ConfirmationFlagTests(TestCase):
    def test_unresolved_line_flagged(self):
        r = _recipe("Mystery Dish")
        _ingredient(r, "sumac", 1, "tsp")  # no canonical

        line = _by_name(aggregate_ingredients([(r, 1)]))["sumac"]
        self.assertIsNone(line.concept_id)
        self.assertIsNone(line.match_confidence)
        self.assertTrue(line.needs_confirmation)

    def test_low_confidence_flagged(self):
        c = CanonicalIngredient.objects.create(canonical_name_en="paprika", category="SP")
        r = _recipe("Stew")
        _ingredient(r, "paprika", 1, "tsp", canonical=c,
                    confidence=NEEDS_CONFIRMATION_THRESHOLD - 0.1)

        line = _by_name(aggregate_ingredients([(r, 1)]))["paprika"]
        self.assertTrue(line.needs_confirmation)

    def test_high_confidence_not_flagged(self):
        c = CanonicalIngredient.objects.create(canonical_name_en="paprika", category="SP")
        r = _recipe("Stew")
        _ingredient(r, "paprika", 1, "tsp", canonical=c, confidence=0.95)

        line = _by_name(aggregate_ingredients([(r, 1)]))["paprika"]
        self.assertFalse(line.needs_confirmation)

    def test_to_dict_shape(self):
        c = CanonicalIngredient.objects.create(
            canonical_name_en="garlic", category="PR", portions={"clove": 3.0},
        )
        r = _recipe("Soup")
        _ingredient(r, "garlic", 2, "clove", canonical=c, confidence=1.0)

        d = aggregate_ingredients([(r, 1)])[0].to_dict()
        self.assertEqual(
            set(d.keys()),
            {"key", "concept_id", "name", "category", "amount", "approx_g", "components",
             "sources", "staple_score", "match_confidence", "needs_confirmation",
             "variants"},
        )
        self.assertEqual(d["key"], f"ci:{c.id}")
        self.assertEqual(set(d["amount"].keys()), {"value", "unit", "dimension"})
        self.assertIsNone(d["staple_score"])  # populated by Part C


class UnitsExtractionTests(TestCase):
    """The extracted units module keeps the legacy behavior intact."""

    def test_normalize_unit_mass_volume_count(self):
        self.assertEqual(units.normalize_unit("kg"), ("mass", "g", 1000.0))
        self.assertEqual(units.normalize_unit("cup"), ("volume", "ml", 240.0))
        self.assertEqual(units.normalize_unit("cloves"), ("count", "clove", 1.0))
        self.assertEqual(units.normalize_unit("fl. oz")[0], "volume")

    def test_legacy_builder_imports_from_units(self):
        from meal_planning import grocery_builder
        self.assertIs(grocery_builder._normalize_unit, units.normalize_unit)
        self.assertIs(grocery_builder._round_qty, units.round_qty)


class StapleSortTests(TestCase):
    """Part C1: staple ordering + always-hidden set."""

    def _canonical(self, name, category):
        return CanonicalIngredient.objects.create(
            canonical_name_en=name, category=category)

    def test_least_likely_first_staple_last(self):
        from rest_framework.test import APIClient
        produce = self._canonical("tomato", "PR")   # score 0.05 -> top
        spice = self._canonical("cumin", "SP")       # score 0.95 -> bottom
        canned = self._canonical("chickpeas", "CJ")  # score 0.60 -> middle
        r = _recipe("Stew")
        _ingredient(r, "cumin", 1, "tsp", canonical=spice, confidence=1.0)
        _ingredient(r, "tomato", 2, "unit", canonical=produce, confidence=1.0)
        _ingredient(r, "chickpeas", 1, "can", canonical=canned, confidence=1.0)

        user = get_user_model().objects.create_user(username="sorter", password="x")
        client = APIClient()
        client.force_authenticate(user)
        client.post("/api/grocery/bag/recipes/", {"recipe_id": r.id}, format="json")

        items = client.get("/api/grocery/bag/").data["items"]
        self.assertEqual([i["name"] for i in items], ["tomato", "chickpeas", "cumin"])
        self.assertEqual(items[0]["staple_score"], 0.05)

    def test_salt_pepper_water_hidden(self):
        from rest_framework.test import APIClient
        salt = self._canonical("salt", "SP")
        tomato = self._canonical("tomato", "PR")
        r = _recipe("Salad")
        _ingredient(r, "salt", 1, "tsp", canonical=salt, confidence=1.0)
        _ingredient(r, "tomato", 2, "unit", canonical=tomato, confidence=1.0)

        user = get_user_model().objects.create_user(username="hider", password="x")
        client = APIClient()
        client.force_authenticate(user)
        client.post("/api/grocery/bag/recipes/", {"recipe_id": r.id}, format="json")

        bag = client.get("/api/grocery/bag/").data
        self.assertEqual([i["name"] for i in bag["items"]], ["tomato"])
        self.assertEqual(bag["hidden_count"], 1)


class GroceryBagEndpointTests(TestCase):
    """Part B CRUD endpoints over the bag."""

    def setUp(self):
        from rest_framework.test import APIClient
        self.user = get_user_model().objects.create_user(username="shopper", password="x")
        self.client = APIClient()
        self.client.force_authenticate(self.user)

        self.garlic = CanonicalIngredient.objects.create(
            canonical_name_en="garlic", category="PR", portions={"clove": 3.0},
        )
        self.recipe = _recipe("Garlic Pasta", servings=2)
        _ingredient(self.recipe, "garlic", 4, "clove", canonical=self.garlic, confidence=1.0)

    def test_requires_auth(self):
        from rest_framework.test import APIClient
        resp = APIClient().get("/api/grocery/bag/")
        self.assertIn(resp.status_code, (401, 403))

    def test_empty_bag(self):
        resp = self.client.get("/api/grocery/bag/")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data["recipes"], [])
        self.assertEqual(resp.data["items"], [])

    def test_add_recipe_then_list(self):
        resp = self.client.post("/api/grocery/bag/recipes/", {"recipe_id": self.recipe.id}, format="json")
        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.data["servings"], 2)  # defaults to recipe.servings

        bag = self.client.get("/api/grocery/bag/").data
        self.assertEqual(len(bag["recipes"]), 1)
        garlic = next(i for i in bag["items"] if i["name"] == "garlic")
        self.assertEqual(garlic["amount"]["value"], 4.0)
        self.assertFalse(garlic["checked"])

    def test_add_recipe_with_servings_scales(self):
        self.client.post("/api/grocery/bag/recipes/",
                         {"recipe_id": self.recipe.id, "servings": 4}, format="json")
        bag = self.client.get("/api/grocery/bag/").data
        garlic = next(i for i in bag["items"] if i["name"] == "garlic")
        self.assertEqual(garlic["amount"]["value"], 8.0)  # 4 cloves * (4/2)

    def test_patch_servings(self):
        add = self.client.post("/api/grocery/bag/recipes/", {"recipe_id": self.recipe.id}, format="json").data
        resp = self.client.patch(f"/api/grocery/bag/recipes/{add['id']}/", {"servings": 6}, format="json")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data["servings"], 6)

    def test_remove_recipe(self):
        add = self.client.post("/api/grocery/bag/recipes/", {"recipe_id": self.recipe.id}, format="json").data
        resp = self.client.delete(f"/api/grocery/bag/recipes/{add['id']}/")
        self.assertEqual(resp.status_code, 204)
        self.assertEqual(self.client.get("/api/grocery/bag/").data["items"], [])

    def test_override_removed_hides_item(self):
        self.client.post("/api/grocery/bag/recipes/", {"recipe_id": self.recipe.id}, format="json")
        key = f"ci:{self.garlic.id}"
        resp = self.client.post("/api/grocery/bag/items/", {"key": key, "state": "removed"}, format="json")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data["items"], [])
        self.assertEqual(resp.data["removed_count"], 1)

    def test_override_checked_then_cleared(self):
        self.client.post("/api/grocery/bag/recipes/", {"recipe_id": self.recipe.id}, format="json")
        key = f"ci:{self.garlic.id}"

        checked = self.client.post("/api/grocery/bag/items/", {"key": key, "state": "checked"}, format="json").data
        self.assertTrue(next(i for i in checked["items"] if i["key"] == key)["checked"])

        self.client.post("/api/grocery/bag/items/", {"key": key}, format="json")  # clear
        bag = self.client.get("/api/grocery/bag/").data
        self.assertFalse(next(i for i in bag["items"] if i["key"] == key)["checked"])

    def test_empty_bag_endpoint(self):
        self.client.post("/api/grocery/bag/recipes/", {"recipe_id": self.recipe.id}, format="json")
        resp = self.client.delete("/api/grocery/bag/")
        self.assertEqual(resp.status_code, 204)
        self.assertEqual(self.client.get("/api/grocery/bag/").data["recipes"], [])

    def test_cannot_touch_other_users_recipe_entry(self):
        add = self.client.post("/api/grocery/bag/recipes/", {"recipe_id": self.recipe.id}, format="json").data
        from rest_framework.test import APIClient
        other = get_user_model().objects.create_user(username="intruder", password="x")
        oc = APIClient()
        oc.force_authenticate(other)
        resp = oc.delete(f"/api/grocery/bag/recipes/{add['id']}/")
        self.assertEqual(resp.status_code, 404)
