from datetime import timedelta

from django.core.cache import cache
from django.test import TestCase
from django.utils import timezone

from home.collectors import (
    FeedContext,
    apply_mood_recipe_filter,
    collect_cook_again,
    collect_event_card,
    collect_explore_rail,
    collect_friend_post,
    collect_grocery_shortcut,
    collect_hero_suggestion,
    collect_meal_plan_nudge,
    collect_mood_question,
)
from home.models import HomeEvent
from meal_planning.models import GroceryList, MealPlan, PlannedMeal
from recipes.models import SavedRecipe
from social.models import Follow, Post

from .helpers import backdate, days_ago, make_recipe, make_user


def make_ctx(user, daypart='evening', is_weekend=False, mood=None):
    return FeedContext(
        user=user, now=timezone.now(), daypart=daypart, is_weekend=is_weekend, mood=mood,
    )


class MoodRecipeFilterTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = make_user('mood_filter_user')
        self.other = make_user('mood_filter_other')
        self.quick = make_recipe('Quick stir fry', self.other, prep=5, cook=10, calories=800)
        self.slow = make_recipe('Slow braise', self.other, prep=30, cook=180, calories=900)
        self.light = make_recipe('Big salad', self.other, prep=10, cook=25, calories=300)

    def test_rushed_filters_to_quick_recipes(self):
        recipes = [self.slow, self.quick, self.light]
        filtered = apply_mood_recipe_filter(recipes, 'rushed')
        for recipe in filtered:
            total = (recipe.preparation_time or 0) + (recipe.cooking_time or 0)
            self.assertLessEqual(total, 30)
        self.assertIn(self.quick, filtered)
        self.assertNotIn(self.slow, filtered)

    def test_healthy_prefers_lower_calories(self):
        recipes = [self.quick, self.slow, self.light]
        filtered = apply_mood_recipe_filter(recipes, 'healthy')
        self.assertEqual(filtered[0], self.light)

    def test_filter_falls_back_when_nothing_matches(self):
        recipes = [self.slow]
        self.assertEqual(apply_mood_recipe_filter(recipes, 'rushed'), [self.slow])

    def test_hero_respects_rushed_mood(self):
        candidates = collect_hero_suggestion(make_ctx(self.user, mood='rushed'))
        self.assertEqual(len(candidates), 1)
        recipe = candidates[0][0]['payload']['recipe']
        self.assertLessEqual(recipe['total_time'], 30)

    def test_explore_rail_respects_healthy_mood(self):
        candidates = collect_explore_rail(make_ctx(self.user, mood='healthy'))
        self.assertEqual(len(candidates), 1)
        recipes = candidates[0][0]['payload']['recipes']
        self.assertEqual(recipes[0]['id'], self.light.id)


class CookAgainTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = make_user('cook_again_user')
        self.other = make_user('cook_again_other')
        self.recipe = make_recipe('Lasagna', self.other)

    def _save(self, when):
        saved = SavedRecipe.objects.create(user=self.user, recipe=self.recipe)
        return backdate(saved, 'saved_at', when)

    def test_saved_10_days_ago_is_surfaced(self):
        self._save(days_ago(10))
        candidates = collect_cook_again(make_ctx(self.user))
        self.assertEqual(len(candidates), 1)
        module = candidates[0][0]
        self.assertEqual(module['module_type'], 'cook_again')
        self.assertEqual(module['payload']['recipe']['id'], self.recipe.id)

    def test_saved_too_recently_is_skipped(self):
        self._save(days_ago(2))
        self.assertEqual(collect_cook_again(make_ctx(self.user)), [])

    def test_saved_too_long_ago_is_skipped(self):
        self._save(days_ago(40))
        self.assertEqual(collect_cook_again(make_ctx(self.user)), [])


class FriendPostTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = make_user('friend_post_user')
        self.friend = make_user('friend_post_friend')
        self.stranger = make_user('friend_post_stranger')
        Follow.objects.create(follower=self.user, followed=self.friend)

    def test_recent_followed_post_is_surfaced(self):
        post = Post.objects.create(user=self.friend, content='Made pasta tonight!')
        candidates = collect_friend_post(make_ctx(self.user))
        self.assertEqual(len(candidates), 1)
        payload = candidates[0][0]['payload']
        self.assertEqual(payload['post_id'], post.id)
        self.assertEqual(payload['author']['username'], 'friend_post_friend')
        self.assertIsNone(payload['recipe'])

    def test_post_older_than_72h_is_skipped(self):
        post = Post.objects.create(user=self.friend, content='Old news')
        backdate(post, 'created_at', days_ago(4))
        self.assertEqual(collect_friend_post(make_ctx(self.user)), [])

    def test_unfollowed_post_is_skipped(self):
        Post.objects.create(user=self.stranger, content='Who am I?')
        self.assertEqual(collect_friend_post(make_ctx(self.user)), [])


class MealPlanAndGroceryTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = make_user('meal_plan_user')
        self.other = make_user('meal_plan_other')
        self.recipe = make_recipe('Tacos', self.other)

    def _current_week_plan(self):
        today = timezone.now().date()
        monday = today - timedelta(days=today.weekday())
        return MealPlan.objects.create(user=self.user, week_start_date=monday)

    def test_no_plan_yields_zero_day_nudge(self):
        candidates = collect_meal_plan_nudge(make_ctx(self.user))
        self.assertEqual(len(candidates), 1)
        payload = candidates[0][0]['payload']
        self.assertEqual(payload['planned_days'], 0)
        self.assertTrue(payload['cta'])

    def test_partial_plan_reports_planned_days(self):
        plan = self._current_week_plan()
        for day in (0, 2):
            PlannedMeal.objects.create(
                meal_plan=plan, recipe=self.recipe, day_of_week=day, meal_type='dinner',
            )
        candidates = collect_meal_plan_nudge(make_ctx(self.user))
        self.assertEqual(len(candidates), 1)
        self.assertEqual(candidates[0][0]['payload']['planned_days'], 2)

    def test_grocery_shortcut_counts_remaining_items(self):
        plan = self._current_week_plan()
        GroceryList.objects.create(
            meal_plan=plan,
            ingredients=[{'name': 'onion'}, {'name': 'beef'}, {'name': 'salt'}],
            purchased_items=[{'name': 'salt'}],
        )
        candidates = collect_grocery_shortcut(make_ctx(self.user))
        self.assertEqual(len(candidates), 1)
        self.assertEqual(candidates[0][0]['payload']['item_count'], 2)

    def test_grocery_shortcut_absent_without_plan(self):
        self.assertEqual(collect_grocery_shortcut(make_ctx(self.user)), [])


class EventCardTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = make_user('event_user')
        self.other = make_user('event_other')
        self.now = timezone.now()

    def _event(self, slug, starts, ends, is_active=True, **kwargs):
        return HomeEvent.objects.create(
            slug=slug, title=slug, starts_at=starts, ends_at=ends,
            is_active=is_active, **kwargs,
        )

    def test_event_inside_window_is_included(self):
        self._event('soup-week', self.now - timedelta(days=1), self.now + timedelta(days=5))
        candidates = collect_event_card(make_ctx(self.user))
        slugs = [c[0]['payload']['event_slug'] for c in candidates]
        self.assertIn('soup-week', slugs)

    def test_event_outside_window_or_inactive_is_excluded(self):
        self._event('not-started', self.now + timedelta(days=1), self.now + timedelta(days=5))
        self._event('ended', self.now - timedelta(days=10), self.now - timedelta(days=2))
        self._event('disabled', self.now - timedelta(days=1), self.now + timedelta(days=1), is_active=False)
        self.assertEqual(collect_event_card(make_ctx(self.user)), [])

    def test_event_priority_scales_base_score(self):
        self._event('big-event', self.now - timedelta(hours=1), self.now + timedelta(days=1), priority=2.5)
        candidates = collect_event_card(make_ctx(self.user))
        self.assertEqual(candidates[0][1], 2.0 * 2.5)

    def test_tag_filter_attaches_up_to_four_recipes(self):
        for i in range(6):
            make_recipe(f"Soup {i}", self.other, tags=['Dinner', 'Soup'])
        self._event(
            'soup-week', self.now - timedelta(days=1), self.now + timedelta(days=5),
            tag_filter='Soup',
        )
        candidates = collect_event_card(make_ctx(self.user))
        recipes = candidates[0][0]['payload']['recipes']
        self.assertEqual(len(recipes), 4)
        for summary in recipes:
            self.assertIn('Soup', summary['tags'])

    def test_computed_friends_event_requires_three_posters(self):
        friends = [make_user(f"event_friend_{i}") for i in range(3)]
        for friend in friends[:2]:
            Follow.objects.create(follower=self.user, followed=friend)
            Post.objects.create(user=friend, content='cooked!')
        # Only 2 distinct followed posters -> no computed event.
        slugs = [c[0]['payload']['event_slug'] for c in collect_event_card(make_ctx(self.user))]
        self.assertNotIn('friends-cooked-this-week', slugs)

        Follow.objects.create(follower=self.user, followed=friends[2])
        Post.objects.create(user=friends[2], content='me too!', recipe=make_recipe('Pie', friends[2]))
        candidates = collect_event_card(make_ctx(self.user))
        computed = [c for c in candidates if c[0]['payload']['event_slug'] == 'friends-cooked-this-week']
        self.assertEqual(len(computed), 1)
        self.assertIn('3 friends cooked this week', computed[0][0]['payload']['title'])

    def test_old_posts_do_not_count_toward_computed_event(self):
        friends = [make_user(f"event_stale_{i}") for i in range(3)]
        for friend in friends:
            Follow.objects.create(follower=self.user, followed=friend)
            post = Post.objects.create(user=friend, content='ancient history')
            backdate(post, 'created_at', days_ago(10))
        slugs = [c[0]['payload']['event_slug'] for c in collect_event_card(make_ctx(self.user))]
        self.assertNotIn('friends-cooked-this-week', slugs)


class MoodQuestionTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = make_user('mood_question_user')

    def test_emitted_only_without_mood(self):
        self.assertEqual(len(collect_mood_question(make_ctx(self.user, mood=None))), 1)
        self.assertEqual(collect_mood_question(make_ctx(self.user, mood='rushed')), [])

    def test_options_cover_locked_mood_taxonomy(self):
        module = collect_mood_question(make_ctx(self.user))[0][0]
        moods = [opt['mood'] for opt in module['payload']['options']]
        self.assertEqual(
            moods,
            ['rushed', 'ambitious', 'cooking_for_someone', 'comfort', 'healthy', 'surprise_me'],
        )
