"""Shared fixtures/assertions for home feed tests."""

from django.contrib.auth import get_user_model
from django.utils import timezone

from recipes.models import Recipe

User = get_user_model()

# Exact contract shapes (plan §1.1 / §1.2 / §1.5) — asserted key-for-key.
RECIPE_SUMMARY_KEYS = {'id', 'title', 'image_url', 'total_time', 'calories', 'tags'}
MODULE_KEYS = {'id', 'module_type', 'reason', 'payload'}
FEED_KEYS = {'feed_id', 'context', 'greeting', 'blocks'}
CONTEXT_KEYS = {'daypart', 'is_weekend', 'mood'}

PAYLOAD_KEYS = {
    'hero_suggestion': {'recipe', 'tagline'},
    'cook_again': {'recipe', 'saved_at'},
    'friend_post': {'post_id', 'author', 'recipe', 'preview_text', 'created_at'},
    'meal_plan_nudge': {'week_start', 'planned_days', 'cta'},
    'grocery_shortcut': {'item_count', 'cta'},
    'chat_prompt': {'prompt_text'},
    'explore_rail': {'title', 'recipes'},
    'event_card': {'event_slug', 'title', 'body', 'image_url', 'cta', 'recipes'},
    'mood_question': {'question', 'options'},
    'deals_rail': {'state', 'postal_code', 'stores', 'total_count', 'items'},
}

DEAL_ITEM_KEYS = {'name', 'name_alt', 'brand', 'price', 'price_value',
                  'discount', 'image_url', 'valid_to', 'merchant', 'distance_m',
                  'savings'}


def make_user(username, **kwargs):
    return User.objects.create_user(username=username, password='test-password', **kwargs)


def make_recipe(title, created_by=None, prep=10, cook=20, calories=None, tags=None, source=None):
    kwargs = {}
    if source is not None:
        kwargs['source'] = source
    return Recipe.objects.create(
        title=title,
        created_by=created_by,
        preparation_time=prep,
        cooking_time=cook,
        calories=calories,
        tags=list(tags) if tags is not None else ['Dinner'],
        **kwargs,
    )


def backdate(instance, field, when):
    """Set an auto_now_add field via a queryset update (bypasses auto_now_add)."""
    type(instance).objects.filter(pk=instance.pk).update(**{field: when})
    instance.refresh_from_db()
    return instance


def days_ago(days, hours=0):
    return timezone.now() - timezone.timedelta(days=days, hours=hours)


def assert_recipe_summary(test, summary):
    test.assertEqual(set(summary.keys()), RECIPE_SUMMARY_KEYS)
    test.assertIsInstance(summary['id'], int)
    test.assertIsInstance(summary['title'], str)
    test.assertIsInstance(summary['tags'], list)


def assert_module_schema(test, module):
    test.assertEqual(set(module.keys()), MODULE_KEYS)
    module_type = module['module_type']
    test.assertIn(module_type, PAYLOAD_KEYS)
    test.assertEqual(
        set(module['payload'].keys()), PAYLOAD_KEYS[module_type],
        f"payload keys mismatch for {module_type}",
    )
    payload = module['payload']
    if module_type in ('hero_suggestion', 'cook_again'):
        assert_recipe_summary(test, payload['recipe'])
    if module_type == 'friend_post':
        test.assertEqual(set(payload['author'].keys()), {'id', 'username', 'avatar_url'})
        if payload['recipe'] is not None:
            assert_recipe_summary(test, payload['recipe'])
    if module_type in ('explore_rail', 'event_card'):
        for summary in payload['recipes']:
            assert_recipe_summary(test, summary)
    if module_type == 'explore_rail':
        test.assertGreaterEqual(len(payload['recipes']), 3)
        test.assertLessEqual(len(payload['recipes']), 8)
    if module_type == 'mood_question':
        for option in payload['options']:
            test.assertEqual(set(option.keys()), {'mood', 'label', 'emoji'})
    if module_type == 'deals_rail':
        test.assertIn(payload['state'], ('setup', 'ready'))
        for item in payload['items']:
            test.assertEqual(set(item.keys()), DEAL_ITEM_KEYS)
