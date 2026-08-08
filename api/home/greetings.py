"""Template greeting pool keyed by daypart and mood (plan WS-B, Tier 1 — no LLM call)."""

# daypart -> [greeting, ...]
DAYPART_GREETINGS = {
    'morning': [
        "Good morning! Let's figure out what's cooking today.",
        "Morning! A little kitchen planning goes a long way.",
        "Rise and shine — what sounds good today?",
    ],
    'midday': [
        "Hey! Lunchtime inspiration, coming right up.",
        "Midday check-in — hungry yet?",
        "Hope your day's going well. Here's what caught my eye for you.",
    ],
    'evening': [
        "Evening! Let's sort out dinner.",
        "Dinner o'clock — here's what I'd cook tonight.",
        "Welcome back! A few ideas for tonight's table.",
    ],
    'late': [
        "Up late? Here's some low-key inspiration.",
        "Night owl mode — maybe plan tomorrow's meals?",
        "Late-night browsing? I've got a few ideas saved up.",
    ],
}

# (daypart, mood) -> [greeting, ...]; falls back to mood-only, then daypart-only.
MOOD_GREETINGS = {
    'rushed': [
        "Short on time? Let's keep it quick tonight.",
        "In a hurry — I picked fast wins for you.",
    ],
    'ambitious': [
        "Feeling ambitious? Let's cook something worth bragging about.",
        "Project-cooking mode: here are some ideas with wow factor.",
    ],
    'cooking_for_someone': [
        "Cooking for someone special? Let's make it memorable.",
        "Hosting tonight? These should impress.",
    ],
    'comfort': [
        "Comfort food kind of day — I've got you.",
        "Cozy mode on. Here's what warms the soul.",
    ],
    'healthy': [
        "Keeping it fresh and light — here's what I found.",
        "Healthy picks, zero sad salads. Promise.",
    ],
    'surprise_me': [
        "Feeling adventurous? Let's shake things up.",
        "Surprise mode: something a little different today.",
    ],
}

DAYPART_MOOD_GREETINGS = {
    ('evening', 'rushed'): [
        "Busy evening? Dinner in 30 or less, coming up.",
    ],
    ('morning', 'healthy'): [
        "A fresh start to the day — light and healthy ideas below.",
    ],
}


def get_greeting(daypart, mood, seed=0):
    """Pick a greeting from the template pool, rotating deterministically by seed."""
    pool = None
    if mood:
        pool = DAYPART_MOOD_GREETINGS.get((daypart, mood)) or MOOD_GREETINGS.get(mood)
    if not pool:
        pool = DAYPART_GREETINGS.get(daypart) or DAYPART_GREETINGS['evening']
    return pool[seed % len(pool)]
