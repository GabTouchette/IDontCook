"""Module collectors for the adaptive home feed (plan WS-B).

Each collector inspects real user signals and returns zero or more
(module_dict, base_score) candidates. Module payloads follow plan §1.2
exactly; recipe summaries follow §1.1. Collectors must never raise for
empty data — a brand-new user still gets a valid feed.
"""

import logging
from dataclasses import dataclass
from datetime import timedelta

from django.db.models import Count, ExpressionWrapper, F, IntegerField

from meal_planning.models import GroceryList, MealPlan, PlannedMeal
from recipes.models import Recipe, SavedRecipe
from social.models import Follow, Post

from .deals_service import aggregate_deals, nearby_stores, resolve_location
from .models import HomeEvent
from .ranking import MOODS
from .serializers import build_module, recipe_summary, recipe_total_time

logger = logging.getLogger(__name__)

RUSHED_MAX_TOTAL_TIME = 30  # §1.3: rushed -> total_time <= 30

# Hero rotates among the top-N recommendations (not always index 0) so refresh
# surfaces a different-but-still-well-matched pick. Widened from 5 -> 8 so the
# hero card visibly changes across revisits/refreshes rather than cycling a tiny
# handful; the pool is still small enough that every pick is well-matched.
HERO_SAMPLE_POOL = 8

# Base scores per module type; mood_question is high so it ranks near the top.
# The three catalog-discovery `explore_rail` variants (catalog-first-pivot.md
# §2/WS-P3) get distinct scores — close to the original personalized rail and
# to each other — so ranking (daypart/mood priors + the library-size weighting
# below), not chance, decides which ones survive MULTI_ALLOWED['explore_rail'].
BASE_SCORES = {
    'hero_suggestion': 3.0,
    'mood_question': 5.0,
    'friend_post': 2.2,
    'cook_again': 2.0,
    'explore_rail': 2.0,
    'explore_rail_trending': 2.15,
    'explore_rail_new': 1.95,
    'explore_rail_theme': 1.75,
    'event_card': 2.0,
    'meal_plan_nudge': 1.8,
    'grocery_shortcut': 1.6,
    'chat_prompt': 1.5,
    'deals_rail': 2.6,
}

# How many sale items to embed in the home-feed deals rail (the full list lives
# behind the "See all deals" CTA -> /api/home/deals/).
DEALS_RAIL_LIMIT = 12


@dataclass
class FeedContext:
    user: object
    now: object  # aware datetime (django.utils.timezone.now())
    daypart: str
    is_weekend: bool
    mood: str = None
    # Device location (from the client's GPS) for the nearby-deals module.
    # None falls back to the user's persisted settings location.
    lat: float = None
    lng: float = None
    # Per-request variety component. Defaults to 0 (fully deterministic, which
    # keeps unit tests stable when they build a FeedContext directly); the view
    # injects a random value per request so refresh/re-rank actually rotates the
    # copy variants and hero pick instead of returning byte-identical content.
    variety_seed: int = 0

    def __post_init__(self):
        self._saved_count = None

    @property
    def rotation_seed(self):
        """Deterministic per-day seed used to rotate copy variants."""
        return self.now.timetuple().tm_yday

    @property
    def copy_seed(self):
        """Seed for rotating copy/selection variants.

        Mixes the stable per-day rotation with the per-request `variety_seed`
        so the same day still has a recognizable base, but each refresh (which
        carries a fresh `variety_seed`) lands on a different greeting/prompt/
        theme/hero pick rather than repeating the exact same feed.
        """
        return self.rotation_seed + self.variety_seed

    @property
    def saved_count(self):
        """The user's own SavedRecipe count, computed once and cached per request.

        Drives the library-size-aware weighting in ranking.py: a user with
        only a handful of saved recipes shouldn't get a feed dominated by
        personal-library modules they don't have enough content in yet.
        """
        if self._saved_count is None:
            self._saved_count = SavedRecipe.objects.filter(user=self.user).count()
        return self._saved_count


# ---------------------------------------------------------------------------
# Recipe selection helpers
# ---------------------------------------------------------------------------

def apply_mood_recipe_filter(recipes, mood):
    """Filter/re-order a list of Recipe instances according to the mood.

    Falls back to the original list when the filter would empty it, so a
    mood never silently kills a module that had candidates.
    """
    recipes = list(recipes)
    if not recipes or not mood:
        return recipes

    if mood == 'rushed':
        quick = [
            r for r in recipes
            if recipe_total_time(r) is not None and recipe_total_time(r) <= RUSHED_MAX_TOTAL_TIME
        ]
        return quick or recipes

    if mood == 'healthy':
        # Lower-calorie *preference*: reorder rather than hard-filter, so
        # modules never starve. Unknown-calorie recipes rank last.
        return sorted(
            recipes,
            key=lambda r: r.calories if r.calories is not None else float('inf'),
        )

    return recipes


def get_recommended_recipes(user, limit=20):
    """Personalized recipe candidates via the recommendations engine.

    Returns [] when the user has no taste profile or the engine fails.
    """
    try:
        from recommendations.api import get_similar_recipes
        recipe_ids = get_similar_recipes(user.id, top_n=limit) or []
    except Exception:
        logger.exception("home feed: get_similar_recipes failed for user %s", user.id)
        recipe_ids = []
    if not recipe_ids:
        return []
    # get_similar_recipes() (recommendations/api.py) only excludes source="ai"
    # on its cold-start path (via get_trending_recipes); the personalized
    # cosine-similarity path does not. Enforce catalog purity here too so
    # hero_suggestion never surfaces an AI-generated recipe as if it were
    # curated content (catalog-first-pivot.md §2/WS-P3 item 4).
    recipes = {
        r.id: r
        for r in Recipe.objects.filter(id__in=recipe_ids).exclude(source=Recipe.SOURCE_AI)
    }
    return [recipes[rid] for rid in recipe_ids if rid in recipes]


def get_popular_recipes(user, limit=20):
    """Fallback pool: most-saved, most recent original catalog recipes not authored by the user."""
    return list(
        Recipe.objects
        .filter(parent__isnull=True)
        .exclude(created_by=user)
        .exclude(source=Recipe.SOURCE_AI)
        .annotate(num_saves=Count('saved_by'))
        .order_by('-num_saves', '-created_at')[:limit]
    )


def _current_meal_plan(ctx):
    """The user's active meal plan covering today, if any."""
    today = ctx.now.date()
    plan = (
        MealPlan.objects
        .filter(user=ctx.user, is_active=True, week_start_date__lte=today)
        .order_by('-week_start_date')
        .first()
    )
    if plan and plan.week_start_date + timedelta(days=6) >= today:
        return plan
    return None


# ---------------------------------------------------------------------------
# Collectors — one per module type
# ---------------------------------------------------------------------------

def collect_hero_suggestion(ctx):
    recipes = get_recommended_recipes(ctx.user) or get_popular_recipes(ctx.user)
    recipes = apply_mood_recipe_filter(recipes, ctx.mood)
    if not recipes:
        return []
    # Rotate within the top of the ranked pool rather than always taking the
    # single top recipe — keeps refresh from showing the identical hero while
    # staying inside the best-matched candidates.
    pool = recipes[:HERO_SAMPLE_POOL]
    recipe = pool[ctx.copy_seed % len(pool)]

    taglines = {
        'rushed': "On the table in no time.",
        'ambitious': "A project worth rolling your sleeves up for.",
        'cooking_for_someone': "Guaranteed to impress at the table.",
        'comfort': "Warm, cozy, and exactly what you need.",
        'healthy': "Fresh, light, and full of flavor.",
        'surprise_me': "Something a little different — trust me.",
    }
    daypart_taglines = {
        'morning': "A head start on today's cooking.",
        'midday': "Just right for lunch.",
        'evening': "Tonight's dinner, sorted.",
        'late': "One to bookmark for tomorrow.",
    }
    tagline = taglines.get(ctx.mood) or daypart_taglines.get(ctx.daypart, "Picked for you.")

    module = build_module(
        f"hero-{recipe.id}",
        'hero_suggestion',
        "Picked for you based on recipes you've cooked and saved",
        {'recipe': recipe_summary(recipe), 'tagline': tagline},
    )
    return [(module, BASE_SCORES['hero_suggestion'])]


def collect_cook_again(ctx):
    saved = (
        SavedRecipe.objects
        .filter(
            user=ctx.user,
            saved_at__lte=ctx.now - timedelta(days=7),
            saved_at__gte=ctx.now - timedelta(days=30),
        )
        .select_related('recipe')
        .order_by('-saved_at')
        .first()
    )
    if not saved or not saved.recipe:
        return []
    module = build_module(
        f"cook-again-{saved.recipe.id}",
        'cook_again',
        "You saved this a little while ago — still sounds good?",
        {'recipe': recipe_summary(saved.recipe), 'saved_at': saved.saved_at.isoformat()},
    )
    return [(module, BASE_SCORES['cook_again'])]


def collect_friend_post(ctx):
    followed_ids = Follow.objects.filter(follower=ctx.user).values_list('followed_id', flat=True)
    if not followed_ids:
        return []
    post = (
        Post.objects
        .filter(user_id__in=followed_ids, created_at__gte=ctx.now - timedelta(hours=72))
        .select_related('user', 'recipe')
        .order_by('-created_at')
        .first()
    )
    if not post:
        return []
    module = build_module(
        f"friend-post-{post.id}",
        'friend_post',
        f"{post.user.username}, who you follow, just posted",
        {
            'post_id': post.id,
            'author': {
                'id': post.user.id,
                'username': post.user.username,
                # CustomUser only has avatar_icon (an icon name, not a URL).
                'avatar_url': None,
            },
            'recipe': recipe_summary(post.recipe) if post.recipe else None,
            'preview_text': (post.content or '')[:200],
            'created_at': post.created_at.isoformat(),
        },
    )
    return [(module, BASE_SCORES['friend_post'])]


def collect_meal_plan_nudge(ctx):
    today = ctx.now.date()
    monday = today - timedelta(days=today.weekday())
    plan = _current_meal_plan(ctx)

    if plan is None:
        module = build_module(
            f"meal-plan-nudge-{monday.isoformat()}",
            'meal_plan_nudge',
            "You haven't planned this week's meals yet",
            {
                'week_start': monday.isoformat(),
                'planned_days': 0,
                'cta': "Plan this week's meals",
            },
        )
        return [(module, BASE_SCORES['meal_plan_nudge'])]

    planned_days = (
        PlannedMeal.objects
        .filter(meal_plan=plan)
        .values('day_of_week')
        .distinct()
        .count()
    )
    if planned_days >= 7:
        return []  # Fully planned — nothing to nudge about.
    module = build_module(
        f"meal-plan-nudge-{plan.week_start_date.isoformat()}",
        'meal_plan_nudge',
        f"Your meal plan covers {planned_days} of 7 days this week",
        {
            'week_start': plan.week_start_date.isoformat(),
            'planned_days': planned_days,
            'cta': "Fill in the rest of your week",
        },
    )
    return [(module, BASE_SCORES['meal_plan_nudge'] * 0.9)]


def collect_grocery_shortcut(ctx):
    plan = _current_meal_plan(ctx)
    if plan is None:
        return []
    grocery_list = GroceryList.objects.filter(meal_plan=plan).first()
    if grocery_list is None:
        return []
    remaining = max(len(grocery_list.ingredients or []) - len(grocery_list.purchased_items or []), 0)
    if remaining == 0:
        return []
    module = build_module(
        f"grocery-shortcut-{grocery_list.id}",
        'grocery_shortcut',
        f"{remaining} items still on this week's grocery list",
        {'item_count': remaining, 'cta': "Open your grocery list"},
    )
    return [(module, BASE_SCORES['grocery_shortcut'])]


CHAT_PROMPTS = {
    # A few discovery-flavored prompts are mixed into each pool (catalog-first
    # -pivot.md §2/WS-P3 item 3) so the rotation exercises the catalog-search
    # -capable chat assistant, not just the personal-library ones.
    'morning': [
        "Plan this week's dinners?",
        "What's a good make-ahead breakfast?",
        "Help me use up what's in my fridge this week.",
        "Surprise me with something from the cookbook.",
    ],
    'midday': [
        "Quick lunch ideas with pantry staples?",
        "What can I prep now to make dinner easier?",
        "Suggest a lunch under 500 calories.",
        "Show me something I've never tried.",
    ],
    'evening': [
        "What should I cook tonight?",
        "Dinner ideas with what's in my fridge?",
        "Give me a one-pot dinner idea.",
        "Find me a spicy noodle dish.",
        "Show me something I've never tried.",
    ],
    'late': [
        "Plan tomorrow's meals for me?",
        "What's a good late-night snack that isn't junk?",
        "Build me a grocery list for next week.",
        "Surprise me with something from the cookbook.",
    ],
}

MOOD_CHAT_PROMPTS = {
    ('evening', 'rushed'): [
        "20-minute ideas with what's in my fridge?",
        "Fastest dinner I can make right now?",
    ],
    ('morning', 'rushed'): [
        "Breakfast I can make in 10 minutes?",
    ],
    ('evening', 'ambitious'): [
        "Give me a weekend-project recipe worth the effort.",
    ],
    ('evening', 'comfort'): [
        "What's the ultimate cozy dinner tonight?",
    ],
}


def collect_chat_prompt(ctx):
    pool = None
    if ctx.mood:
        pool = MOOD_CHAT_PROMPTS.get((ctx.daypart, ctx.mood))
    if not pool:
        pool = CHAT_PROMPTS.get(ctx.daypart) or CHAT_PROMPTS['evening']
    prompt_text = pool[ctx.copy_seed % len(pool)]
    module = build_module(
        'chat-prompt-1',
        'chat_prompt',
        "Tap to ask — I'll take it from there",
        {'prompt_text': prompt_text},
    )
    return [(module, BASE_SCORES['chat_prompt'])]


def collect_explore_rail(ctx):
    recipes = get_recommended_recipes(ctx.user, limit=24)
    personalized = bool(recipes)
    if not recipes:
        recipes = get_popular_recipes(ctx.user, limit=24)
    recipes = apply_mood_recipe_filter(recipes, ctx.mood)[:6]
    if len(recipes) < 3:  # §1.2: explore_rail carries 3-8 recipes
        return []

    titles = {
        'rushed': "Fast wins for busy days",
        'ambitious': "Level-up projects",
        'cooking_for_someone': "Crowd pleasers",
        'comfort': "Comfort classics",
        'healthy': "Fresh and light",
        'surprise_me': "Off the beaten path",
    }
    daypart_titles = {
        'morning': "Ideas to start the day",
        'midday': "Lunch inspiration",
        'evening': "Tonight's contenders",
        'late': "Save these for tomorrow",
    }
    title = titles.get(ctx.mood) or daypart_titles.get(ctx.daypart, "Discover something new")
    reason = (
        "Based on your taste profile" if personalized
        else "Popular with the community right now"
    )
    module = build_module(
        'explore-rail-1',
        'explore_rail',
        reason,
        {'title': title, 'recipes': [recipe_summary(r) for r in recipes]},
    )
    return [(module, BASE_SCORES['explore_rail'])]


# ---------------------------------------------------------------------------
# Catalog-discovery explore_rail variants (catalog-first-pivot.md §2/WS-P3)
#
# These reuse the existing `explore_rail` module type/schema (no new contract)
# but each gets its own id/title so the mobile client renders them as three
# separate rails. They share a running `exclude_ids` set (built by
# collect_catalog_discovery_rails below) so trending/new/theme don't all
# surface the same handful of recipes.
# ---------------------------------------------------------------------------

# Rotating theme pool for explore-rail-theme. Mix of tag-based and
# time-based themes; tags are the real (title-case) tag strings used in the
# catalog data (spot-checked against the dev DB: "Soup" ~103, "Chicken" ~167,
# "Vegetarian" ~262, "Dessert" ~513, "Breakfast" ~170, "Quick" ~209 recipes).
THEME_POOL = [
    {'title': "Soups for a cold night", 'tags': ['Soup']},
    {'title': "30-minute weeknight wins", 'max_total_time': 30},
    {'title': "Something with chicken", 'tags': ['Chicken']},
    {'title': "Vegetarian favorites", 'tags': ['Vegetarian']},
    {'title': "Sweet tooth calling", 'tags': ['Dessert']},
    {'title': "Breakfast, any time of day", 'tags': ['Breakfast']},
    {'title': "Fast fixes for busy nights", 'tags': ['Quick']},
    {'title': "20-minute meals", 'max_total_time': 20},
]


def _theme_candidates(theme, exclude_ids, limit=8):
    """Catalog recipes matching a THEME_POOL entry's tags and/or max_total_time."""
    qs = Recipe.objects.filter(source=Recipe.SOURCE_CATALOG).exclude(id__in=exclude_ids)

    max_total_time = theme.get('max_total_time')
    if max_total_time is not None:
        qs = qs.filter(
            preparation_time__isnull=False, cooking_time__isnull=False,
        ).annotate(
            _rail_total_time=ExpressionWrapper(
                F('preparation_time') + F('cooking_time'), output_field=IntegerField(),
            ),
        ).filter(_rail_total_time__lte=max_total_time)

    tags = theme.get('tags')
    if not tags:
        return list(qs.order_by('-created_at')[:limit])

    try:
        tagged_qs = qs
        for tag in tags:
            tagged_qs = tagged_qs.filter(tags__contains=[tag])
        return list(tagged_qs.order_by('-created_at')[:limit])
    except Exception:
        # JSONField __contains is unavailable on some backends; degrade in Python
        # (mirrors _event_recipes_for_tag below).
        matches = []
        for recipe in qs.exclude(tags__isnull=True).order_by('-created_at')[:1000]:
            if all(tag in (recipe.tags or []) for tag in tags):
                matches.append(recipe)
                if len(matches) >= limit:
                    break
        return matches


def collect_explore_rail_trending(ctx, exclude_ids=frozenset()):
    """explore-rail-trending: 'Popular right now' via get_trending_recipes."""
    try:
        from recommendations.api import get_trending_recipes
        recipe_ids = get_trending_recipes(ctx.user.id, exclude_ids=exclude_ids, top_n=8) or []
    except Exception:
        logger.exception("home feed: get_trending_recipes failed for user %s", ctx.user.id)
        recipe_ids = []
    if not recipe_ids:
        return []
    recipes_by_id = {r.id: r for r in Recipe.objects.filter(id__in=recipe_ids)}
    recipes = [recipes_by_id[rid] for rid in recipe_ids if rid in recipes_by_id]
    recipes = apply_mood_recipe_filter(recipes, ctx.mood)[:8]
    if len(recipes) < 3:  # §1.2: explore_rail carries 3-8 recipes
        return []
    module = build_module(
        'explore-rail-trending',
        'explore_rail',
        "Popular with the community right now",
        {'title': "Popular right now", 'recipes': [recipe_summary(r) for r in recipes]},
    )
    return [(module, BASE_SCORES['explore_rail_trending'])]


def collect_explore_rail_new(ctx, exclude_ids=frozenset()):
    """explore-rail-new: most recently added catalog recipes."""
    recipes = list(
        Recipe.objects
        .filter(source=Recipe.SOURCE_CATALOG)
        .exclude(id__in=exclude_ids)
        .order_by('-created_at')[:8]
    )
    recipes = apply_mood_recipe_filter(recipes, ctx.mood)[:8]
    if len(recipes) < 3:
        return []
    module = build_module(
        'explore-rail-new',
        'explore_rail',
        "Freshly added to the cookbook",
        {'title': "New in the cookbook", 'recipes': [recipe_summary(r) for r in recipes]},
    )
    return [(module, BASE_SCORES['explore_rail_new'])]


def collect_explore_rail_theme(ctx, exclude_ids=frozenset()):
    """explore-rail-theme: a rotating tag/time theme picked from THEME_POOL.

    Deterministic per-day rotation via ctx.rotation_seed. Falls back to the
    next theme in rotation order when the picked one has fewer than 3
    matches, rather than emitting a thin/empty rail.
    """
    n = len(THEME_POOL)
    start = ctx.copy_seed % n
    for offset in range(n):
        theme = THEME_POOL[(start + offset) % n]
        recipes = _theme_candidates(theme, exclude_ids, limit=8)
        recipes = apply_mood_recipe_filter(recipes, ctx.mood)[:8]
        if len(recipes) >= 3:
            module = build_module(
                'explore-rail-theme',
                'explore_rail',
                "A themed pick for today",
                {'title': theme['title'], 'recipes': [recipe_summary(r) for r in recipes]},
            )
            return [(module, BASE_SCORES['explore_rail_theme'])]
    return []


def collect_catalog_discovery_rails(ctx):
    """Runs trending/new/theme together, sharing a running exclude set so the
    three rails don't all surface the same recipes."""
    candidates = []
    shown_ids = set()
    for collector in (
        collect_explore_rail_trending,
        collect_explore_rail_new,
        collect_explore_rail_theme,
    ):
        for module, score in collector(ctx, exclude_ids=shown_ids):
            candidates.append((module, score))
            shown_ids.update(r['id'] for r in module['payload']['recipes'])
    return candidates


def _event_recipes_for_tag(tag, limit=4):
    if not tag:
        return []
    try:
        return list(Recipe.objects.filter(tags__contains=[tag])[:limit])
    except Exception:
        # JSONField __contains is unavailable on some backends; degrade in Python.
        matches = []
        for recipe in Recipe.objects.exclude(tags__isnull=True).only('id')[:500]:
            if tag in (recipe.tags or []):
                matches.append(recipe)
                if len(matches) >= limit:
                    break
        return matches


def collect_event_card(ctx):
    candidates = []
    active_events = HomeEvent.objects.filter(
        is_active=True, starts_at__lte=ctx.now, ends_at__gte=ctx.now,
    ).order_by('-priority')
    for event in active_events:
        recipes = _event_recipes_for_tag(event.tag_filter)
        module = build_module(
            f"event-{event.slug}",
            'event_card',
            "Happening now",
            {
                'event_slug': event.slug,
                'title': event.title,
                'body': event.body,
                'image_url': event.image_url or None,
                'cta': event.cta or None,
                'recipes': [recipe_summary(r) for r in recipes],
            },
        )
        candidates.append((module, BASE_SCORES['event_card'] * event.priority))

    # Computed event: "N friends cooked this week" when >= 3 followed users posted.
    followed_ids = list(Follow.objects.filter(follower=ctx.user).values_list('followed_id', flat=True))
    if followed_ids:
        week_posts = Post.objects.filter(
            user_id__in=followed_ids, created_at__gte=ctx.now - timedelta(days=7),
        )
        cook_count = week_posts.values('user_id').distinct().count()
        if cook_count >= 3:
            recipe_ids = list(
                week_posts.exclude(recipe__isnull=True)
                .order_by('-created_at')
                .values_list('recipe_id', flat=True)
            )
            seen, unique_ids = set(), []
            for rid in recipe_ids:
                if rid not in seen:
                    seen.add(rid)
                    unique_ids.append(rid)
                if len(unique_ids) >= 4:
                    break
            recipe_map = {r.id: r for r in Recipe.objects.filter(id__in=unique_ids)}
            recipes = [recipe_map[rid] for rid in unique_ids if rid in recipe_map]
            module = build_module(
                'event-friends-cooked-this-week',
                'event_card',
                "Your friends have been busy in the kitchen",
                {
                    'event_slug': 'friends-cooked-this-week',
                    'title': f"{cook_count} friends cooked this week",
                    'body': "See what people you follow have been making.",
                    'image_url': None,
                    'cta': "See what they made",
                    'recipes': [recipe_summary(r) for r in recipes],
                },
            )
            candidates.append((module, BASE_SCORES['event_card']))
    return candidates


MOOD_QUESTION_VARIANTS = [
    "What's the vibe today?",
    "How are you feeling about cooking right now?",
    "What kind of cooking day is it?",
]

MOOD_OPTIONS = [
    {'mood': 'rushed', 'label': 'Rushed', 'emoji': '⏱️'},
    {'mood': 'ambitious', 'label': 'Ambitious', 'emoji': '🔥'},
    {'mood': 'cooking_for_someone', 'label': 'Cooking for someone', 'emoji': '💝'},
    {'mood': 'comfort', 'label': 'Comfort', 'emoji': '🛋️'},
    {'mood': 'healthy', 'label': 'Healthy', 'emoji': '🥗'},
    {'mood': 'surprise_me', 'label': 'Surprise me', 'emoji': '🎲'},
]

assert [opt['mood'] for opt in MOOD_OPTIONS] == MOODS


def collect_mood_question(ctx):
    if ctx.mood:  # Only asked when no mood is set for the session.
        return []
    question = MOOD_QUESTION_VARIANTS[ctx.copy_seed % len(MOOD_QUESTION_VARIANTS)]
    module = build_module(
        'mood-question-1',
        'mood_question',
        "Tell me your mood and I'll re-rank the feed",
        {'question': question, 'options': [dict(opt) for opt in MOOD_OPTIONS]},
    )
    return [(module, BASE_SCORES['mood_question'])]


def _deal_item(item):
    """Trim a FlippClient item to the display fields the deals rail needs."""
    return {
        'name': item['name'],
        'name_alt': item.get('name_alt'),
        'brand': item.get('brand') or '',
        'price': item.get('price'),
        'price_value': item.get('price_value'),
        'discount': item.get('discount'),
        'image_url': item.get('image_url'),
        'valid_to': item.get('valid_to'),
        # Which nearby store this deal is from, how far, and $ saved.
        'merchant': item.get('merchant') or '',
        'distance_m': item.get('distance_m'),
        'savings': item.get('savings'),
    }


# Number of nearest stores to aggregate deals across for the home rail.
DEALS_STORE_LIMIT = 5


def collect_deals(ctx):
    """The biggest grocery discounts near the user, across their nearest stores.

    Location-driven (no manual store pick): uses the client GPS coords from the
    feed request, else the user's persisted settings location. Two states, both
    on the same `deals_rail` module:
      * `setup`  — no location available -> an "enable location" prompt. Kept
        low-ish so it doesn't dominate a feed for a user who hasn't opted in.
      * `ready`  — top discounts pooled from the DEALS_STORE_LIMIT closest
        stores, deepest discount first, each item tagged with its store.

    Never raises: any Flipp/OSM failure yields [] (collect_modules also guards).
    """
    settings = getattr(ctx.user, 'settings', None)
    lat, lng = ctx.lat, ctx.lng
    if lat is None or lng is None:
        lat = getattr(settings, 'latitude', None) if settings else None
        lng = getattr(settings, 'longitude', None) if settings else None
    postal = (getattr(settings, 'postal_code', '') or '').strip() if settings else ''

    lat, lng, postal = resolve_location(lat=lat, lng=lng, postal=postal)

    if len(postal) < 6:
        payload = {
            'state': 'setup',
            'postal_code': None,
            'stores': [],
            'total_count': 0,
            'items': [],
        }
        module = build_module(
            'deals-setup',
            'deals_rail',
            'Turn on location to see the best deals near you',
            payload,
        )
        return [(module, BASE_SCORES['deals_rail'] * 0.7)]

    stores = nearby_stores(postal, lat, lng, store_limit=DEALS_STORE_LIMIT)
    if not stores:
        return []
    items = aggregate_deals(stores)
    if not items:
        return []

    payload = {
        'state': 'ready',
        'postal_code': postal,
        'stores': [
            {
                'merchant': s['merchant'],
                'merchant_id': s['merchant_id'],
                'merchant_logo': s.get('logo_url'),
                'distance_m': s.get('distance_m'),
            }
            for s in stores
        ],
        'total_count': len(items),
        'items': [_deal_item(it) for it in items[:DEALS_RAIL_LIMIT]],
    }
    module = build_module(
        'deals-nearby',
        'deals_rail',
        'Best deals near you right now',
        payload,
    )
    return [(module, BASE_SCORES['deals_rail'])]


# Active collectors, in tie-break priority order.
#
# `collect_meal_plan_nudge` and `collect_chat_prompt` are intentionally NOT
# wired in: product removed the static meal-plan card and the bottom
# "What should I cook tonight" chat-prompt chip from the home feed (they read
# as fixed furniture rather than responsive content). The collector functions
# (and their unit tests) are kept so the modules can be re-enabled by adding
# them back to this list — nothing else references them at feed-build time.
COLLECTORS = [
    collect_mood_question,
    collect_hero_suggestion,
    collect_friend_post,
    collect_cook_again,
    collect_event_card,
    collect_explore_rail,
    collect_catalog_discovery_rails,
    collect_grocery_shortcut,
    collect_deals,
]


def collect_modules(ctx):
    """Run every collector, tolerating individual failures (no 500s on bad data)."""
    candidates = []
    for collector in COLLECTORS:
        try:
            candidates.extend(collector(ctx))
        except Exception:
            logger.exception("home feed: collector %s failed", collector.__name__)
    return candidates
