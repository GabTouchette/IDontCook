"""Tests for the catalog-first ingredient resolution + per-ingredient portions.

Covers Path A (resolver: exact/alias/fuzzy; grocery merging on canonical id) and
Path B (portion-aware gram conversion; USDA foodPortions parsing). LLM-dependent
branches are exercised with ``use_llm=False`` so the suite stays offline.
"""

from django.contrib.auth import get_user_model
from django.test import TestCase

from recipes import ingredient_resolver
from recipes.models import CanonicalIngredient, Ingredient, Recipe
from recipes.nutrition_service import NutritionService
from recipes.usda_api import USDAClient


class IngredientResolverTests(TestCase):
    def setUp(self):
        ingredient_resolver.clear_cache()
        self.garlic = CanonicalIngredient.objects.create(
            canonical_name_en="garlic", canonical_name_fr="ail", category="PR"
        )
        self.green_onion = CanonicalIngredient.objects.create(
            canonical_name_en="green onion",
            canonical_name_fr="oignon vert",
            # "escallion" is a real alias the name-normalizer does NOT rewrite, so
            # it genuinely exercises the alias path (unlike "scallion", which the
            # normalizer already maps to "green onion" and would hit 'exact').
            aliases_en=["escallion"],
            category="PR",
        )
        ingredient_resolver.clear_cache()  # pick up the rows just created

    def test_exact_match(self):
        res = ingredient_resolver.resolve("Garlic", use_llm=False)
        self.assertEqual(res.canonical_id, self.garlic.id)
        self.assertEqual(res.method, "exact")
        self.assertEqual(res.confidence, 1.0)

    def test_exact_match_via_usda_cleaning(self):
        # "garlic cloves, minced" -> clean_for_usda strips "cloves"/"minced" -> "garlic".
        res = ingredient_resolver.resolve("garlic cloves, minced", use_llm=False)
        self.assertEqual(res.canonical_id, self.garlic.id)
        self.assertEqual(res.method, "exact")

    def test_synonym_normalized_to_exact(self):
        # The name-normalizer rewrites "scallions" -> "green onion" before lookup,
        # so it resolves correctly (via the exact path).
        res = ingredient_resolver.resolve("scallions", use_llm=False)
        self.assertEqual(res.canonical_id, self.green_onion.id)

    def test_alias_match(self):
        res = ingredient_resolver.resolve("escallion", use_llm=False)
        self.assertEqual(res.canonical_id, self.green_onion.id)
        self.assertEqual(res.method, "alias")
        self.assertGreaterEqual(res.confidence, 0.9)

    def test_fuzzy_match(self):
        res = ingredient_resolver.resolve("garic", use_llm=False)  # typo
        self.assertEqual(res.canonical_id, self.garlic.id)
        self.assertEqual(res.method, "fuzzy")
        self.assertLess(res.confidence, 1.0)

    def test_no_match(self):
        res = ingredient_resolver.resolve("plutonium", use_llm=False)
        self.assertFalse(res.matched)
        self.assertEqual(res.method, "none")

    def test_empty_input(self):
        self.assertFalse(ingredient_resolver.resolve("", use_llm=False).matched)


class PortionAwareConversionTests(TestCase):
    def setUp(self):
        self.service = NutritionService()
        # Flour: 1 cup is 120g (USDA-ish), not the 240ml * 0.6 density guess (144g).
        self.flour = CanonicalIngredient.objects.create(
            canonical_name_en="all-purpose flour",
            category="BK",
            portions={"cup": 120.0, "tbsp": 7.5},
            density_g_per_ml=0.5,
        )
        self.egg = CanonicalIngredient.objects.create(
            canonical_name_en="egg", category="PR", portions={"medium": 44.0}
        )

    def test_portion_wins_for_household_unit(self):
        grams = self.service._convert_to_grams(2, "cup", "flour", canonical=self.flour)
        self.assertEqual(grams, 240.0)  # 2 * 120

    def test_count_prefers_canonical_per_item_weight(self):
        grams = self.service._convert_to_grams(3, "", "egg", canonical=self.egg)
        self.assertEqual(grams, 132.0)  # 3 * 44

    def test_density_used_when_no_matching_portion(self):
        # 'ml' isn't in portions -> falls to per-food density (0.5 g/ml).
        grams = self.service._convert_to_grams(100, "ml", "flour", canonical=self.flour)
        self.assertEqual(grams, 50.0)

    def test_mass_unit_ignores_canonical(self):
        grams = self.service._convert_to_grams(50, "g", "flour", canonical=self.flour)
        self.assertEqual(grams, 50.0)

    def test_fallback_without_canonical_unchanged(self):
        # No canonical -> legacy behaviour (count default 50g/item).
        self.assertEqual(self.service._convert_to_grams(2, "", "apple"), 100.0)


class USDAParsingTests(TestCase):
    def test_parse_detail_nutrition(self):
        detail = {
            "fdcId": 12345,
            "description": "Butter, salted",
            "foodNutrients": [
                {"nutrient": {"id": 1008}, "amount": 717},
                {"nutrient": {"id": 1003}, "amount": 0.85},
                {"nutrient": {"id": 1004}, "amount": 81.1},
                {"nutrient": {"id": 1005}, "amount": 0.06},
            ],
        }
        n = USDAClient.parse_detail_nutrition(detail)
        self.assertIsNotNone(n)
        self.assertEqual(n["calories"], 717)
        self.assertEqual(n["fat"], 81.1)
        self.assertEqual(n["fdc_id"], "12345")

    def test_parse_detail_nutrition_calories_from_macros(self):
        detail = {
            "fdcId": 1,
            "foodNutrients": [
                {"nutrient": {"id": 1003}, "amount": 10},  # protein
                {"nutrient": {"id": 1005}, "amount": 20},  # carbs
                {"nutrient": {"id": 1004}, "amount": 5},   # fat
            ],
        }
        n = USDAClient.parse_detail_nutrition(detail)
        self.assertEqual(n["calories"], 10 * 4 + 20 * 4 + 5 * 9)  # 165

    def test_parse_food_portions(self):
        detail = {
            "foodPortions": [
                {"amount": 1, "gramWeight": 136, "measureUnit": {"name": "cup"}},
                {"amount": 1, "gramWeight": 8.5, "measureUnit": {"name": "tablespoon"}},
                {"amount": 1, "gramWeight": 3, "measureUnit": {"name": "undetermined"},
                 "modifier": "clove"},
                {"amount": 2, "gramWeight": 10, "measureUnit": {"name": "undetermined"},
                 "modifier": "slice"},  # 2 slices -> 5g each
            ]
        }
        portions = USDAClient.parse_food_portions(detail)
        self.assertEqual(portions["cup"], 136.0)
        self.assertEqual(portions["tbsp"], 8.5)
        self.assertEqual(portions["clove"], 3.0)
        self.assertEqual(portions["slice"], 5.0)

    def test_parse_food_portions_keeps_smallest_duplicate(self):
        detail = {
            "foodPortions": [
                {"amount": 1, "gramWeight": 150, "measureUnit": {"name": "cup"}},
                {"amount": 1, "gramWeight": 120, "measureUnit": {"name": "cup"}},
            ]
        }
        self.assertEqual(USDAClient.parse_food_portions(detail)["cup"], 120.0)


class FdcScoringTests(TestCase):
    def test_prefers_tight_match_over_bloated_description(self):
        from recipes.management.commands.backfill_canonical_fdc_ids import best_match

        candidates = [
            {"fdc_id": "1", "description": "Butter, salted", "data_type": "Foundation"},
            {"fdc_id": "2", "description": "Butter, with olive oil, salted spread",
             "data_type": "Branded"},
        ]
        match, score = best_match("butter", candidates)
        self.assertEqual(match["fdc_id"], "1")
        self.assertGreater(score, 0.5)

    def test_data_type_breaks_ties_toward_generic(self):
        from recipes.management.commands.backfill_canonical_fdc_ids import score_candidate

        foundation = score_candidate("egg", "Egg, whole, raw", "Foundation")
        branded = score_candidate("egg", "Egg, whole, raw", "Branded")
        self.assertGreater(foundation, branded)

    def test_no_overlap_scores_zero(self):
        from recipes.management.commands.backfill_canonical_fdc_ids import score_candidate

        self.assertEqual(score_candidate("garlic", "Beef, ground", "Foundation"), 0.0)


class CatalogCleaningTests(TestCase):
    def test_deterministic_clean_reduces_to_base(self):
        from recipes.catalog_cleaning import deterministic_clean

        self.assertEqual(deterministic_clean("garlic clove finely"), "garlic")
        self.assertEqual(deterministic_clean("garlic cloves pressed"), "garlic")
        self.assertEqual(deterministic_clean("egg lightly beaten"), "egg")
        self.assertEqual(deterministic_clean("Chicken breast, boneless skinless"), "chicken breast")

    def test_real_multiword_ingredient_is_not_ambiguous(self):
        from recipes.catalog_cleaning import deterministic_clean, is_ambiguous

        for name in ("olive oil", "soy sauce", "chicken breast"):
            cleaned = deterministic_clean(name)
            self.assertFalse(is_ambiguous(name, cleaned), f"{name} -> {cleaned}")

    def test_verbose_phrase_is_ambiguous(self):
        from recipes.catalog_cleaning import deterministic_clean, is_ambiguous

        name = "garlic cloves with a microplane grater"
        cleaned = deterministic_clean(name)
        # Either it reduces cleanly to "garlic" (not ambiguous) or it's flagged
        # for Claude — never silently kept as a phrase.
        if cleaned != "garlic":
            self.assertTrue(is_ambiguous(name, cleaned))

    def test_merge_survivor_and_fk_repoint(self):
        from django.contrib.auth import get_user_model
        from django.core.management import call_command

        user = get_user_model().objects.create_user(username="cleaner", password="x")
        garlic = CanonicalIngredient.objects.create(canonical_name_en="garlic", category="PR")
        clove = CanonicalIngredient.objects.create(canonical_name_en="garlic clove finely")
        recipe = Recipe.objects.create(title="r", created_by=user, servings=1)
        ing = Ingredient.objects.create(name="garlic clove finely", canonical=clove)
        recipe.ingredients.add(ing)

        call_command("clean_canonical_catalog", "--apply", "--samples", "0")

        # The junk row is gone and the ingredient now points at the clean survivor.
        self.assertFalse(CanonicalIngredient.objects.filter(id=clove.id).exists())
        ing.refresh_from_db()
        self.assertEqual(ing.canonical_id, garlic.id)

    def test_failed_llm_leaves_ambiguous_untouched(self):
        """Regression: an empty LLM mapping (auth failure etc.) must NOT merge the
        unclassified rows — they stay as distinct rows."""
        from unittest.mock import patch
        from django.core.management import call_command

        # Two verbose, ambiguous names that the deterministic pass can't clean.
        a = CanonicalIngredient.objects.create(
            canonical_name_en="chicken simmered with white wine and herbs for serving")
        b = CanonicalIngredient.objects.create(
            canonical_name_en="beef braised low and slow with red wine reduction")
        before = CanonicalIngredient.objects.count()

        with patch(
            "recipes.management.commands.clean_canonical_catalog.Command._llm_classify",
            return_value={},
        ):
            call_command("clean_canonical_catalog", "--apply", "--use-llm", "--samples", "0")

        self.assertEqual(CanonicalIngredient.objects.count(), before)
        self.assertTrue(CanonicalIngredient.objects.filter(id=a.id).exists())
        self.assertTrue(CanonicalIngredient.objects.filter(id=b.id).exists())


class GroceryMergeTests(TestCase):
    def setUp(self):
        from meal_planning.grocery_builder import build_grocery_list  # noqa: F401
        self.user = get_user_model().objects.create_user(
            username="grocer", password="x"
        )
        self.green_onion = CanonicalIngredient.objects.create(
            canonical_name_en="green onion", category="PR"
        )

    def _recipe_with(self, raw_name):
        recipe = Recipe.objects.create(title=f"r-{raw_name}", created_by=self.user, servings=1)
        ing = Ingredient.objects.create(
            name=raw_name, quantity=100, unit="g", canonical=self.green_onion
        )
        recipe.ingredients.add(ing)  # ingredients is a ManyToManyField
        return recipe

    def test_merges_on_canonical_concept(self):
        from meal_planning.models import MealPlan, PlannedMeal
        from meal_planning.grocery_builder import build_grocery_list

        # Two recipes, same concept via different surface names.
        r1 = self._recipe_with("scallions")
        r2 = self._recipe_with("spring onions")
        plan = MealPlan.objects.create(user=self.user, week_start_date="2026-01-01")
        PlannedMeal.objects.create(meal_plan=plan, recipe=r1, day_of_week=0,
                                   meal_type="dinner", servings=1)
        PlannedMeal.objects.create(meal_plan=plan, recipe=r2, day_of_week=1,
                                   meal_type="dinner", servings=1)

        grocery = build_grocery_list(plan)
        green = [row for row in grocery if row["name"] == "green onion"]
        self.assertEqual(len(green), 1, grocery)
        self.assertEqual(green[0]["quantity"], 200.0)  # 100g + 100g merged
        self.assertEqual(green[0]["unit"], "g")
