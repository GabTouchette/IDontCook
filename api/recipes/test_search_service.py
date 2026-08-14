"""Tests for search_catalog() (docs/plans/catalog-first-pivot.md §1.5, WS-P1)."""

from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase

from recipes.models import Ingredient, Recipe
from recipes.search_service import search_catalog

User = get_user_model()


def _make_recipe(created_by, title, tags=None, source=Recipe.SOURCE_CATALOG,
                  ingredient_names=None, description="", preparation_time=None,
                  cooking_time=None, calories=None):
    recipe = Recipe.objects.create(
        title=title,
        description=description,
        tags=tags or ["Dinner"],
        created_by=created_by,
        source=source,
        preparation_time=preparation_time,
        cooking_time=cooking_time,
        calories=calories,
    )
    for name in (ingredient_names or []):
        ingredient = Ingredient.objects.create(name=name)
        recipe.ingredients.add(ingredient)
    return recipe


class SearchCatalogTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="searcher", password="pass1234")

        self.chicken_stir_fry = _make_recipe(
            self.user, "Chicken Stir Fry",
            tags=["Dinner", "Asian"],
            ingredient_names=["chicken", "soy sauce", "broccoli"],
            description="A quick weeknight stir fry",
            preparation_time=10,
            cooking_time=15,
            calories=450,
        )
        self.beef_stew = _make_recipe(
            self.user, "Beef Stew",
            tags=["Dinner", "Comfort"],
            ingredient_names=["beef", "potato", "carrot"],
            description="Slow-cooked hearty stew",
            preparation_time=20,
            cooking_time=120,
            calories=600,
        )
        self.quick_salad = _make_recipe(
            self.user, "Garden Salad",
            tags=["Lunch", "Quick"],
            ingredient_names=["lettuce", "tomato", "cucumber"],
            description="A light and fast salad",
            preparation_time=5,
            cooking_time=0,
            calories=150,
        )
        self.ai_recipe = _make_recipe(
            self.user, "AI Chicken Stir Fry Deluxe",
            tags=["Dinner", "Asian"],
            source=Recipe.SOURCE_AI,
            ingredient_names=["chicken", "soy sauce"],
            description="A generated stir fry",
            preparation_time=10,
            cooking_time=15,
            calories=450,
        )

    def test_lexical_match(self):
        results = search_catalog("chicken stir fry", user=self.user)
        ids = [r.id for r in results]
        self.assertIn(self.chicken_stir_fry.id, ids)
        # The real catalog match should outrank (or at least appear before)
        # unrelated recipes.
        self.assertLess(ids.index(self.chicken_stir_fry.id), len(ids))

    def test_source_ai_never_appears(self):
        results = search_catalog("chicken stir fry", user=self.user, limit=15)
        ids = [r.id for r in results]
        self.assertNotIn(self.ai_recipe.id, ids)

        # Also true for other query shapes, including empty query.
        results_empty = search_catalog("", user=self.user, limit=15)
        self.assertNotIn(self.ai_recipe.id, [r.id for r in results_empty])

    def test_filter_combination_tags_and_time(self):
        # Both stir fry (25 min total) and salad (5 min total) are quick;
        # stew (140 min total) is not. Restrict to Dinner tag + <=30 min:
        # only the stir fry should qualify.
        results = search_catalog(
            "", user=self.user, tags=["Dinner"], max_total_time=30, limit=15
        )
        ids = {r.id for r in results}
        self.assertIn(self.chicken_stir_fry.id, ids)
        self.assertNotIn(self.beef_stew.id, ids)  # too long
        self.assertNotIn(self.quick_salad.id, ids)  # wrong tag

    def test_exclude_ids_respected(self):
        results = search_catalog(
            "chicken stir fry", user=self.user, exclude_ids=[self.chicken_stir_fry.id]
        )
        ids = [r.id for r in results]
        self.assertNotIn(self.chicken_stir_fry.id, ids)

    def test_empty_query_returns_something(self):
        results = search_catalog("", user=self.user, limit=15)
        self.assertTrue(len(results) > 0)

    def test_never_raises_when_recommender_pieces_are_broken(self):
        with patch(
            "recipes.search_service._semantic_scores",
            side_effect=RuntimeError("boom"),
        ):
            results = search_catalog("chicken stir fry", user=self.user)
            self.assertIsInstance(results, list)
            self.assertTrue(len(results) > 0)

        with patch(
            "recipes.search_service._candidate_queryset",
            side_effect=RuntimeError("boom"),
        ):
            results = search_catalog("chicken stir fry", user=self.user)
            self.assertEqual(results, [])

    def test_bad_input_does_not_raise(self):
        # Nonsense limit, tags, exclude_ids types should degrade gracefully.
        results = search_catalog(
            "chicken", user=self.user, tags=None, max_total_time=None,
            max_calories=None, exclude_ids=(), limit=0,
        )
        self.assertIsInstance(results, list)

        results_none_user = search_catalog("chicken", user=None)
        self.assertIsInstance(results_none_user, list)
