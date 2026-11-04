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


class DimensionFromUnitsTests(TestCase):
    """Dimension follows the recipe's units, not a mis-curated category."""

    def test_count_item_in_mass_category(self):
        # pork chops: category MS (mass prior) but the recipe counts them
        chop = CanonicalIngredient.objects.create(
            canonical_name_en="pork chop", category="MS")
        r = _recipe("BBQ")
        _ingredient(r, "pork chops", 4, "piece", canonical=chop, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r, 1)]))["pork chop"]
        self.assertEqual(line.amount.dimension, "count")
        self.assertEqual(line.amount.value, 4.0)
        self.assertEqual(line.amount.unit, "piece")
        self.assertEqual(line.components, [])  # no stray "g + 4 piece"

    def test_volume_only_line_stays_volume(self):
        ginger = CanonicalIngredient.objects.create(
            canonical_name_en="ginger", category="PR")
        r = _recipe("Stir-fry")
        _ingredient(r, "ginger", 1, "ml", canonical=ginger, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r, 1)]))["ginger"]
        self.assertEqual(line.amount.dimension, "volume")
        self.assertEqual(line.amount.value, 1.0)
        self.assertEqual(line.components, [])  # no stray "6 g + 1 ml"

    def test_pc_normalizes_and_merges_with_piece(self):
        pepper = CanonicalIngredient.objects.create(
            canonical_name_en="bell pepper", category="PR")
        r1 = _recipe("A")
        r2 = _recipe("B")
        _ingredient(r1, "bell pepper", 1, "pc", canonical=pepper, confidence=1.0)
        _ingredient(r2, "bell peppers", 2, "piece", canonical=pepper, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r1, 1), (r2, 1)]))["bell pepper"]
        self.assertEqual(line.amount.unit, "piece")
        self.assertEqual(line.amount.value, 3.0)  # 1 pc + 2 piece merged
        self.assertEqual(line.components, [])


class SourceUnitTests(TestCase):
    """Provenance keeps the recipe's own unit, not the normalized base label."""

    def test_source_keeps_tablespoon_not_ml(self):
        oil = CanonicalIngredient.objects.create(
            canonical_name_en="canola oil", category="CO")
        r = _recipe("Fry")
        _ingredient(r, "canola oil", 2, "tbsp", canonical=oil, confidence=1.0)

        line = _by_name(aggregate_ingredients([(r, 1)]))["canola oil"]
        self.assertEqual(line.amount.value, 30.0)        # 2 tbsp -> 30 ml
        self.assertEqual(line.sources[0].unit, "tbsp")   # not "ml"
        self.assertEqual(line.sources[0].quantity, 2.0)


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

    def test_salt_pepper_water_hidden_and_revealable(self):
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
        # The hidden item is returned separately so the UI can reveal it.
        self.assertEqual([i["name"] for i in bag["hidden_items"]], ["salt"])


class LocalizationTests(TestCase):
    """Open question resolved: display names localize via ?lang=, keys don't."""

    def test_fr_display_name_keeps_en_key(self):
        from rest_framework.test import APIClient
        garlic = CanonicalIngredient.objects.create(
            canonical_name_en="garlic", canonical_name_fr="ail", category="PR")
        r = _recipe("Aioli")
        _ingredient(r, "garlic", 2, "clove", canonical=garlic, confidence=1.0)

        user = get_user_model().objects.create_user(username="fruser", password="x")
        client = APIClient()
        client.force_authenticate(user)
        client.post("/api/grocery/bag/recipes/", {"recipe_id": r.id}, format="json")

        fr = client.get("/api/grocery/bag/", {"lang": "fr"}).data["items"][0]
        self.assertEqual(fr["name"], "ail")            # localized display
        self.assertEqual(fr["key"], f"ci:{garlic.id}")  # identity unchanged

        en = client.get("/api/grocery/bag/").data["items"][0]
        self.assertEqual(en["name"], "garlic")

    def test_fr_falls_back_to_en_when_missing(self):
        from rest_framework.test import APIClient
        thyme = CanonicalIngredient.objects.create(
            canonical_name_en="thyme", category="SP")  # no fr
        r = _recipe("Stock")
        _ingredient(r, "thyme", 1, "unit", canonical=thyme, confidence=1.0)

        user = get_user_model().objects.create_user(username="fru2", password="x")
        client = APIClient()
        client.force_authenticate(user)
        client.post("/api/grocery/bag/recipes/", {"recipe_id": r.id}, format="json")

        fr = client.get("/api/grocery/bag/", {"lang": "fr"}).data["items"][0]
        self.assertEqual(fr["name"], "thyme")


class PantryTests(TestCase):
    """Part C2: 'I always have this' sinks items to the bottom."""

    def setUp(self):
        from rest_framework.test import APIClient
        self.user = get_user_model().objects.create_user(username="pantryuser", password="x")
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.tomato = CanonicalIngredient.objects.create(
            canonical_name_en="tomato", category="PR")   # 0.05 normally top
        self.beef = CanonicalIngredient.objects.create(
            canonical_name_en="beef", category="MS")      # 0.05 normally top
        r = _recipe("Bolognese")
        _ingredient(r, "tomato", 2, "unit", canonical=self.tomato, confidence=1.0)
        _ingredient(r, "beef", 400, "g", canonical=self.beef, confidence=1.0)
        self.client.post("/api/grocery/bag/recipes/", {"recipe_id": r.id}, format="json")

    def test_mark_pantry_sinks_to_bottom(self):
        key = f"ci:{self.tomato.id}"
        resp = self.client.post(
            "/api/grocery/pantry/", {"key": key, "in_pantry": True}, format="json")
        self.assertEqual(resp.status_code, 200)
        items = resp.data["items"]
        tomato = next(i for i in items if i["key"] == key)
        self.assertEqual(tomato["staple_score"], 1.0)
        self.assertTrue(tomato["in_pantry"])
        self.assertEqual(items[-1]["key"], key)  # sorted to the very bottom

    def test_unmark_pantry(self):
        key = f"ci:{self.tomato.id}"
        self.client.post("/api/grocery/pantry/", {"key": key, "in_pantry": True}, format="json")
        resp = self.client.post(
            "/api/grocery/pantry/", {"key": key, "in_pantry": False}, format="json")
        tomato = next(i for i in resp.data["items"] if i["key"] == key)
        self.assertFalse(tomato["in_pantry"])
        self.assertEqual(tomato["staple_score"], 0.05)


class ResolveTests(TestCase):
    """Part D2: confirm step links unresolved lines to a canonical concept."""

    def setUp(self):
        from rest_framework.test import APIClient
        self.user = get_user_model().objects.create_user(username="resolver", password="x")
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_search_canonical(self):
        CanonicalIngredient.objects.create(canonical_name_en="smoked paprika", category="SP")
        CanonicalIngredient.objects.create(canonical_name_en="garlic", category="PR")
        resp = self.client.get("/api/grocery/bag/resolve/search/", {"q": "papri"})
        self.assertEqual(resp.status_code, 200)
        names = [r["name"] for r in resp.data["results"]]
        self.assertIn("smoked paprika", names)
        self.assertNotIn("garlic", names)

    def test_search_too_short(self):
        resp = self.client.get("/api/grocery/bag/resolve/search/", {"q": "a"})
        self.assertEqual(resp.data["results"], [])

    def test_resolve_links_unresolved_line(self):
        sumac = CanonicalIngredient.objects.create(canonical_name_en="sumac", category="SP")
        r = _recipe("Fattoush")
        ing = _ingredient(r, "sumac", 1, "tsp")  # unresolved, canonical=None
        self.client.post("/api/grocery/bag/recipes/", {"recipe_id": r.id}, format="json")

        key = "name:sumac"
        bag = self.client.get("/api/grocery/bag/").data
        line = next(i for i in bag["items"] if i["key"] == key)
        self.assertTrue(line["needs_confirmation"])

        resp = self.client.post(
            "/api/grocery/bag/resolve/",
            {"key": key, "concept_id": sumac.id}, format="json")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data["updated"], 1)

        # The ingredient row now points at the canonical, method=user.
        ing.refresh_from_db()
        self.assertEqual(ing.canonical_id, sumac.id)
        self.assertEqual(ing.canonical_confidence, 1.0)
        self.assertEqual(ing.resolution_method, "user")

        # The list line is now resolved (keyed on ci:) and no longer flagged.
        bag2 = self.client.get("/api/grocery/bag/").data
        line2 = next(i for i in bag2["items"] if i["name"] == "sumac")
        self.assertEqual(line2["key"], f"ci:{sumac.id}")
        self.assertFalse(line2["needs_confirmation"])

    def test_resolve_does_not_overwrite_high_confidence(self):
        existing = CanonicalIngredient.objects.create(canonical_name_en="basil", category="PR")
        other = CanonicalIngredient.objects.create(canonical_name_en="mint", category="PR")
        r = _recipe("Pesto")
        ing = _ingredient(r, "basil", 10, "g", canonical=existing, confidence=0.99)
        self.client.post("/api/grocery/bag/recipes/", {"recipe_id": r.id}, format="json")

        resp = self.client.post(
            "/api/grocery/bag/resolve/",
            {"key": f"ci:{existing.id}", "concept_id": other.id}, format="json")
        self.assertEqual(resp.data["updated"], 0)  # high-confidence row left alone
        ing.refresh_from_db()
        self.assertEqual(ing.canonical_id, existing.id)


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
