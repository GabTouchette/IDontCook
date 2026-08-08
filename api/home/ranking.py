"""Rules ranker for the adaptive home feed (plan WS-B).

Final module score = base_score
                     x DAYPART_PRIORS[(daypart, is_weekend)].get(module_type, 1.0)
                     x MOOD_PRIORS[mood].get(module_type, 1.0)

All priors are plain dicts so they can be tuned without code changes elsewhere.
Missing keys always default to 1.0 (neutral).
"""

# §1.3 mood taxonomy (LOCKED)
MOODS = [
    'rushed',
    'ambitious',
    'cooking_for_someone',
    'comfort',
    'healthy',
    'surprise_me',
]

DAYPARTS = ['morning', 'midday', 'evening', 'late']

# Raised 6 -> 7 (catalog-first-pivot.md §2/WS-P3) to make room for a third
# explore_rail instance (trending/new/theme) without displacing the existing
# personal-library modules a returning user still relies on.
MAX_MODULES = 7

# Module types allowed to appear more than once in a single feed.
MULTI_ALLOWED = {
    'event_card': 2,
    # Up to 3 explore_rail instances (personalized/trending/new/theme
    # candidates compete; ranking decides which 3 survive) — catalog-first
    # -pivot.md §2/WS-P3.
    'explore_rail': 3,
}

# --- Library-size-aware weighting (catalog-first-pivot.md §2/WS-P3 item 2) -
#
# A brand-new user (saved_count == 0) is already handled: collect_cook_again
# and collect_meal_plan_nudge naturally return [] with no saved recipes / no
# meal plan. This weighting targets the *partial* case (1-4 saved recipes),
# where those modules would otherwise still outrank discovery content even
# though the user doesn't have enough personal library yet for them to be
# very useful. Threshold and multipliers are deliberately conservative and
# easy to retune:
#   - LOW_LIBRARY_THRESHOLD = 5: fewer than 5 saved recipes counts as "not an
#     established library yet" (chosen as a round number a couple of weeks of
#     casual use would clear; not derived from data).
#   - 0.5x on cook_again/meal_plan_nudge: halve their pull without hiding them
#     outright — they can still surface if nothing else is competitive.
#   - 1.35x on hero_suggestion/explore_rail: a moderate discovery boost, sized
#     to reliably flip ordering against a halved personal-library score
#     without single-handedly dominating every daypart/mood prior.
LOW_LIBRARY_THRESHOLD = 5
LOW_LIBRARY_PERSONAL_MULTIPLIER = 0.5
LOW_LIBRARY_DISCOVERY_MULTIPLIER = 1.35
LOW_LIBRARY_PERSONAL_TYPES = {'cook_again', 'meal_plan_nudge'}
LOW_LIBRARY_DISCOVERY_TYPES = {'hero_suggestion', 'explore_rail'}


def apply_library_size_weighting(candidates, saved_count):
    """Multiply base scores per the low-library rule above.

    No-op when `saved_count` is None (caller opted out) or >= threshold.
    """
    if saved_count is None or saved_count >= LOW_LIBRARY_THRESHOLD:
        return candidates
    weighted = []
    for module, base_score in candidates:
        module_type = module['module_type']
        if module_type in LOW_LIBRARY_PERSONAL_TYPES:
            base_score = base_score * LOW_LIBRARY_PERSONAL_MULTIPLIER
        elif module_type in LOW_LIBRARY_DISCOVERY_TYPES:
            base_score = base_score * LOW_LIBRARY_DISCOVERY_MULTIPLIER
        weighted.append((module, base_score))
    return weighted


def compute_daypart(local_hour):
    """§1.4: computed from CLIENT-provided local hour, never server clock.

    morning 05-11, midday 11-15, evening 15-21, late 21-05.
    """
    if 5 <= local_hour < 11:
        return 'morning'
    if 11 <= local_hour < 15:
        return 'midday'
    if 15 <= local_hour < 21:
        return 'evening'
    return 'late'


# (daypart, is_weekend) -> {module_type: multiplier}
DAYPART_PRIORS = {
    # Weekday mornings: planning headspace.
    ('morning', False): {
        'meal_plan_nudge': 1.6,
        'chat_prompt': 1.4,
        'grocery_shortcut': 1.2,
        'hero_suggestion': 0.9,
        'friend_post': 0.9,
    },
    # Weekend mornings: browsing, social.
    ('morning', True): {
        'explore_rail': 1.4,
        'friend_post': 1.35,
        'event_card': 1.3,
        'chat_prompt': 1.15,
        'meal_plan_nudge': 1.1,
    },
    ('midday', False): {
        'hero_suggestion': 1.25,
        'chat_prompt': 1.1,
        'grocery_shortcut': 1.1,
    },
    ('midday', True): {
        'friend_post': 1.4,
        'explore_rail': 1.4,
        'event_card': 1.3,
        'hero_suggestion': 1.1,
    },
    # Weekday evenings: "what's for dinner right now".
    ('evening', False): {
        'hero_suggestion': 1.6,
        'cook_again': 1.3,
        'grocery_shortcut': 1.1,
        'meal_plan_nudge': 0.8,
    },
    # Weekend evenings: social + ambitious cooking.
    ('evening', True): {
        'friend_post': 1.4,
        'explore_rail': 1.4,
        'event_card': 1.4,
        'hero_suggestion': 1.3,
    },
    # Late nights: low-commitment browsing and planning ahead.
    ('late', False): {
        'chat_prompt': 1.3,
        'explore_rail': 1.25,
        'meal_plan_nudge': 1.2,
        'hero_suggestion': 0.8,
    },
    ('late', True): {
        'explore_rail': 1.4,
        'friend_post': 1.3,
        'event_card': 1.2,
        'hero_suggestion': 0.8,
    },
}

# mood -> {module_type: multiplier}
MOOD_PRIORS = {
    'rushed': {
        'hero_suggestion': 1.4,
        'chat_prompt': 1.3,
        'explore_rail': 1.1,
        'cook_again': 1.1,
        'friend_post': 0.7,
        'event_card': 0.7,
        'meal_plan_nudge': 0.6,
    },
    'ambitious': {
        'explore_rail': 1.5,
        'hero_suggestion': 1.3,
        'event_card': 1.2,
        'cook_again': 0.8,
    },
    'cooking_for_someone': {
        'hero_suggestion': 1.4,
        'explore_rail': 1.3,
        'friend_post': 1.2,
        'cook_again': 1.1,
    },
    'comfort': {
        'cook_again': 1.5,
        'hero_suggestion': 1.2,
        'friend_post': 1.1,
        'explore_rail': 1.05,
    },
    'healthy': {
        'hero_suggestion': 1.4,
        'explore_rail': 1.3,
        'meal_plan_nudge': 1.2,
        'event_card': 0.9,
    },
    'surprise_me': {
        'explore_rail': 1.5,
        'event_card': 1.3,
        'chat_prompt': 1.2,
        'hero_suggestion': 0.9,
    },
}


def score_module(module_type, base_score, daypart, is_weekend, mood):
    daypart_prior = DAYPART_PRIORS.get((daypart, is_weekend), {}).get(module_type, 1.0)
    mood_prior = MOOD_PRIORS.get(mood, {}).get(module_type, 1.0) if mood else 1.0
    return base_score * daypart_prior * mood_prior


def rank_modules(candidates, daypart, is_weekend, mood, max_modules=MAX_MODULES, saved_count=None):
    """Score, sort, dedup and cap candidate modules.

    `candidates` is a list of (module_dict, base_score) tuples. `saved_count`
    (optional) triggers the library-size-aware weighting above; omitted or
    None leaves scoring unchanged (backward compatible with existing callers).
    Returns the final ordered list of module dicts.
    """
    candidates = apply_library_size_weighting(candidates, saved_count)
    scored = []
    for module, base_score in candidates:
        score = score_module(module['module_type'], base_score, daypart, is_weekend, mood)
        scored.append((score, module))

    # Stable sort: highest score first; ties keep collector order.
    scored.sort(key=lambda pair: -pair[0])

    ranked = []
    seen_ids = set()
    type_counts = {}
    for _score, module in scored:
        module_type = module['module_type']
        allowed = MULTI_ALLOWED.get(module_type, 1)
        if type_counts.get(module_type, 0) >= allowed:
            continue
        if module['id'] in seen_ids:
            continue
        ranked.append(module)
        seen_ids.add(module['id'])
        type_counts[module_type] = type_counts.get(module_type, 0) + 1
        if len(ranked) >= max_modules:
            break
    return ranked
