from datetime import timedelta

from django.core.cache import cache
from django.utils import timezone
from rest_framework.test import APITestCase

from home.models import HomeEvent
from home.ranking import MAX_MODULES
from social.models import Follow, Post

from .helpers import (
    CONTEXT_KEYS,
    FEED_KEYS,
    assert_module_schema,
    make_recipe,
    make_user,
)

FEED_URL = '/api/home/feed/'


class FeedViewValidationTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = make_user('feed_validation_user')
        self.client.force_authenticate(user=self.user)

    def test_requires_authentication(self):
        self.client.force_authenticate(user=None)
        response = self.client.get(FEED_URL, {'local_hour': 17, 'weekday': 4})
        self.assertEqual(response.status_code, 401)

    def test_local_hour_required_and_bounded(self):
        self.assertEqual(self.client.get(FEED_URL, {'weekday': 4}).status_code, 400)
        self.assertEqual(
            self.client.get(FEED_URL, {'local_hour': 24, 'weekday': 4}).status_code, 400)
        self.assertEqual(
            self.client.get(FEED_URL, {'local_hour': 'abc', 'weekday': 4}).status_code, 400)

    def test_weekday_required_and_bounded(self):
        self.assertEqual(self.client.get(FEED_URL, {'local_hour': 17}).status_code, 400)
        self.assertEqual(
            self.client.get(FEED_URL, {'local_hour': 17, 'weekday': 7}).status_code, 400)

    def test_invalid_mood_rejected(self):
        response = self.client.get(
            FEED_URL, {'local_hour': 17, 'weekday': 4, 'mood': 'hangry'})
        self.assertEqual(response.status_code, 400)


class FeedSchemaTests(APITestCase):
    """Response schema conformance against plan §1.5 / §1.2 / §1.1."""

    def setUp(self):
        cache.clear()
        self.user = make_user('feed_schema_user')
        self.other = make_user('feed_schema_other')
        self.client.force_authenticate(user=self.user)
        for i in range(5):
            make_recipe(f"Community dish {i}", self.other, prep=10, cook=15, calories=400 + i)
        Follow.objects.create(follower=self.user, followed=self.other)
        Post.objects.create(user=self.other, content='Dinner was great')
        now = timezone.now()
        HomeEvent.objects.create(
            slug='soup-week', title='Soup week', body='All soup, all week.',
            starts_at=now - timedelta(days=1), ends_at=now + timedelta(days=5),
        )

    def test_feed_matches_locked_contract(self):
        response = self.client.get(FEED_URL, {'local_hour': 17, 'weekday': 4})
        self.assertEqual(response.status_code, 200)
        data = response.json()

        self.assertEqual(set(data.keys()), FEED_KEYS)
        self.assertEqual(set(data['context'].keys()), CONTEXT_KEYS)
        self.assertEqual(data['context']['daypart'], 'evening')
        self.assertFalse(data['context']['is_weekend'])
        self.assertIsNone(data['context']['mood'])
        self.assertIsInstance(data['feed_id'], str)
        self.assertTrue(data['greeting'])

        blocks = data['blocks']
        self.assertGreaterEqual(len(blocks), 2)
        # blocks[0] is the greeting text block.
        self.assertEqual(blocks[0], {'block_type': 'text', 'text': data['greeting']})
        module_blocks = blocks[1:]
        self.assertLessEqual(len(module_blocks), MAX_MODULES)
        for block in module_blocks:
            self.assertEqual(set(block.keys()), {'block_type', 'module'})
            self.assertEqual(block['block_type'], 'module')
            assert_module_schema(self, block['module'])
        # Module ids are unique within a feed.
        ids = [b['module']['id'] for b in module_blocks]
        self.assertEqual(len(ids), len(set(ids)))

    def test_mood_question_present_without_mood_and_absent_with_mood(self):
        without = self.client.get(FEED_URL, {'local_hour': 9, 'weekday': 1}).json()
        types = [b['module']['module_type'] for b in without['blocks'][1:]]
        self.assertIn('mood_question', types)
        # Ranks near the top of the module list.
        self.assertLessEqual(types.index('mood_question'), 1)

        with_mood = self.client.get(
            FEED_URL, {'local_hour': 9, 'weekday': 1, 'mood': 'comfort'}).json()
        types = [b['module']['module_type'] for b in with_mood['blocks'][1:]]
        self.assertNotIn('mood_question', types)
        self.assertEqual(with_mood['context']['mood'], 'comfort')

    def test_weekend_flag_and_dayparts(self):
        data = self.client.get(FEED_URL, {'local_hour': 23, 'weekday': 6}).json()
        self.assertEqual(data['context']['daypart'], 'late')
        self.assertTrue(data['context']['is_weekend'])

    def test_active_event_appears_in_feed(self):
        data = self.client.get(FEED_URL, {'local_hour': 11, 'weekday': 5}).json()
        events = [
            b['module'] for b in data['blocks'][1:]
            if b['module']['module_type'] == 'event_card'
        ]
        self.assertTrue(events)
        self.assertEqual(events[0]['payload']['event_slug'], 'soup-week')


class NewUserFallbackTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = make_user('brand_new_user')
        self.client.force_authenticate(user=self.user)

    def test_new_user_with_popular_recipes_gets_valid_feed(self):
        other = make_user('community_author')
        for i in range(4):
            make_recipe(f"Popular dish {i}", other)
        response = self.client.get(FEED_URL, {'local_hour': 17, 'weekday': 2})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        types = [b['module']['module_type'] for b in data['blocks'][1:]]
        # Minimum viable feed for a cold-start user.
        self.assertIn('explore_rail', types)
        self.assertIn('chat_prompt', types)
        self.assertIn('mood_question', types)
        for block in data['blocks'][1:]:
            assert_module_schema(self, block['module'])

    def test_new_user_gets_proportionally_more_explore_rail_content(self):
        """catalog-first-pivot.md §2/WS-P3: a brand-new user's feed should be
        weighted toward catalog discovery rather than personal-library
        modules they don't have content for yet."""
        other = make_user('community_author_2')
        for i in range(10):
            make_recipe(f"Catalog dish {i}", other, source='catalog')
        response = self.client.get(FEED_URL, {'local_hour': 17, 'weekday': 2})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        types = [b['module']['module_type'] for b in data['blocks'][1:]]
        # More than the single legacy explore_rail — the new discovery rail
        # variants (new/theme; trending needs interaction signal this user
        # doesn't have yet) now compete alongside the personalized/popular one.
        self.assertGreaterEqual(types.count('explore_rail'), 2)

    def test_completely_empty_database_still_returns_feed(self):
        response = self.client.get(FEED_URL, {'local_hour': 8, 'weekday': 0})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        types = [b['module']['module_type'] for b in data['blocks'][1:]]
        self.assertIn('chat_prompt', types)
        self.assertIn('mood_question', types)
