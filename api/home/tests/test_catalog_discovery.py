"""Tests for the catalog-discovery explore_rail variants and the
library-size-aware weighting (docs/plans/catalog-first-pivot.md §2/WS-P3)."""

from datetime import datetime

from django.core.cache import cache
from django.test import TestCase
from django.utils import timezone

from home.collectors import (
    THEME_POOL,
    FeedContext,
    collect_catalog_discovery_rails,
    collect_explore_rail_new,
    collect_explore_rail_theme,
)
from recipes.models import SavedRecipe

from .helpers import backdate, days_ago, make_recipe, make_user


def make_ctx(user, now=None, daypart='evening', is_weekend=False, mood=None):
    return FeedContext(
        user=user, now=now or timezone.now(), daypart=daypart, is_weekend=is_weekend, mood=mood,
    )


class CatalogDiscoveryRailTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = make_user('discovery_user')
        self.other = make_user('discovery_other')
        self.saver1 = make_user('discovery_saver1')
        self.saver2 = make_user('discovery_saver2')

    def test_trending_and_new_rails_do_not_duplicate_recipes(self):
        # "Hot" recipes: catalog, recently created, and saved by several
        # users -> eligible for BOTH the trending pool (has save signal) and
        # the new pool (recent) if the shared exclude set didn't work.
        hot = [
            make_recipe(f"Hot {i}", self.other, source='catalog', tags=['Dinner'])
            for i in range(3)
        ]
        for recipe in hot:
            SavedRecipe.objects.create(user=self.saver1, recipe=recipe)
            SavedRecipe.objects.create(user=self.saver2, recipe=recipe)

        # Older catalog recipes with no save signal: not trending-eligible,
        # but real candidates for "new in the cookbook" once the hot ones
        # are excluded.
        older = [
            make_recipe(f"Older {i}", self.other, source='catalog', tags=['Dinner'])
            for i in range(4)
        ]
        for recipe in older:
            backdate(recipe, 'created_at', days_ago(10))

        candidates = collect_catalog_discovery_rails(make_ctx(self.user))
        modules_by_id = {module['id']: module for module, _ in candidates}

        self.assertIn('explore-rail-trending', modules_by_id)
        self.assertIn('explore-rail-new', modules_by_id)

        trending_ids = {
            r['id'] for r in modules_by_id['explore-rail-trending']['payload']['recipes']
        }
        new_ids = {r['id'] for r in modules_by_id['explore-rail-new']['payload']['recipes']}

        # The hot (saved) recipes are the ones with trending signal.
        self.assertTrue(trending_ids & {r.id for r in hot})
        # No recipe is repeated across the two rails.
        self.assertEqual(trending_ids & new_ids, set())

        all_ids = []
        for module, _ in candidates:
            all_ids.extend(r['id'] for r in module['payload']['recipes'])
        self.assertEqual(len(all_ids), len(set(all_ids)), "recipe repeated across rail variants")

    def test_new_rail_orders_by_recency_and_catalog_source_only(self):
        newest = make_recipe("Newest catalog", self.other, source='catalog')
        middle = make_recipe("Middle catalog", self.other, source='catalog')
        oldest = make_recipe("Oldest catalog", self.other, source='catalog')
        backdate(middle, 'created_at', days_ago(2))
        backdate(oldest, 'created_at', days_ago(5))
        # Not source="catalog" -> must never appear in "new in the cookbook".
        user_owned = make_recipe("User's own recipe", self.other, source='user')

        result = collect_explore_rail_new(make_ctx(self.user))
        self.assertEqual(len(result), 1)
        module = result[0][0]
        self.assertEqual(module['payload']['title'], "New in the cookbook")
        recipe_ids = [r['id'] for r in module['payload']['recipes']]

        self.assertEqual(recipe_ids, [newest.id, middle.id, oldest.id])
        self.assertNotIn(user_owned.id, recipe_ids)

    def test_theme_rail_falls_back_when_first_pick_has_too_few_matches(self):
        # Only "Chicken"-tagged catalog recipes exist; total_time is 45min
        # so no time-based theme matches either. Jan 8 -> tm_yday=8,
        # 8 % len(THEME_POOL) == 0, landing on THEME_POOL[0] ("Soup", 0
        # matches), then THEME_POOL[1] (30-min, 0 matches since 45 > 30),
        # before finally landing on THEME_POOL[2] ("Something with chicken").
        self.assertEqual(THEME_POOL[0]['tags'], ['Soup'])
        self.assertEqual(THEME_POOL[2]['tags'], ['Chicken'])

        for i in range(3):
            make_recipe(
                f"Chicken dish {i}", self.other, source='catalog',
                tags=['Chicken'], prep=20, cook=25,
            )
        jan8 = timezone.make_aware(datetime(2024, 1, 8, 12, 0))
        ctx = make_ctx(self.user, now=jan8)
        self.assertEqual(ctx.rotation_seed % len(THEME_POOL), 0)

        result = collect_explore_rail_theme(ctx)
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0][0]['payload']['title'], "Something with chicken")
