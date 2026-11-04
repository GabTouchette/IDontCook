"""Canonical recipe-tag vocabulary + canonicalizer.

Why this exists
---------------
`Recipe.tags` is a free-form JSONField, and three write paths (AI generation,
`auto_tag_recipes`, the bulk importers) historically poured whatever they liked
into it. The BBC Good Food / AllRecipes imports in particular dumped raw site
taxonomy — author bylines ("Josh Eagleton"), nutrient labels ("Fibre",
"2 of 5-a-day"), kcal/time/serving bands ("400 kcal or less", "4 servings"),
and ingredient names ("Chicken", "Salmon") — straight into the tag list. The
result was ~4,400 distinct tags across the catalog, which makes tags useless for
browsing or filtering.

This module is the *single source of truth* for the small, curated set of tags
the app actually browses and filters by. `Recipe.save()` runs every write
through `canonicalize_tags`, and the `clean_recipe_tags` management command runs
the same function over the existing catalog. The Flutter picker mirrors
`CANONICAL_TAGS` in `mobile/lib/utils/constants.dart` — keep the two in sync.

The rules are deliberately simple:
  * a tag that matches a canonical tag case-insensitively is kept (in canonical
    casing);
  * a tag listed in `TAG_ALIASES` (a near-miss / known variant) is remapped;
  * anything else is dropped.
"""

from collections import OrderedDict

# Curated vocabulary, grouped for the picker UI. The flat set is what actually
# gets enforced; the grouping only drives presentation (and the Flutter mirror).
CANONICAL_TAGS = OrderedDict([
    ("Meal Types", [
        "Breakfast", "Lunch", "Dinner", "Snack", "Dessert",
        "Brunch", "Appetizer", "Beverage", "Cocktail",
    ]),
    ("Dietary", [
        "Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free",
        "Keto", "High Protein", "Low Carb",
    ]),
    ("Cooking Methods", [
        "Baked", "Grilled", "Air Fryer", "Slow Cooker", "One-Pot", "No Cook",
    ]),
    ("Dish Types", [
        "Soup", "Salad", "Pasta", "Pizza", "Curry",
        "Stir-Fry", "Sandwich", "Stew", "Bread",
    ]),
    ("Cuisines", [
        "Italian", "Mexican", "Asian", "Indian", "Mediterranean", "American",
        "French", "Thai", "Chinese", "Japanese", "Middle Eastern",
    ]),
    ("Convenience", [
        "Quick", "30-Minute Meal", "Budget-Friendly",
        "Meal Prep", "5 Ingredients or Less",
    ]),
    ("Other", [
        "Comfort Food", "Healthy", "Spicy",
    ]),
])

# Flat canonical set and a lowercase lookup for case-insensitive exact matches.
CANONICAL_TAG_SET = [t for tags in CANONICAL_TAGS.values() for t in tags]
_CANON_BY_LOWER = {t.lower(): t for t in CANONICAL_TAG_SET}

# The five required meal types (mirrors Recipe.REQUIRED_MEAL_TYPES). Kept here so
# canonicalization can enforce "at most one meal type" without importing models.
REQUIRED_MEAL_TYPES = ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert"]

# Known near-misses / variants → canonical tag. Keys MUST be lowercase; matching
# is done on `str(tag).strip().lower()`. Anything not matched here (and not an
# exact canonical tag) is dropped. Built from the real catalog tag distribution.
TAG_ALIASES = {
    # --- Meal types / sections ---
    "desserts": "Dessert",
    "cookies": "Dessert", "biscuits": "Dessert", "biscotti": "Dessert",
    "brownie": "Dessert", "brownies": "Dessert",
    "cake": "Dessert", "cakes": "Dessert", "cheesecake": "Dessert",
    "pie": "Dessert", "pies": "Dessert", "fruit pies": "Dessert",
    "apple pie": "Dessert", "fudge": "Dessert", "pastry": "Dessert",
    "breakfast and brunch": "Brunch",
    "appetizers and snacks": "Appetizer",
    "starter": "Appetizer", "starters": "Appetizer",
    "dips and spreads": "Appetizer", "cheese dips and spreads": "Appetizer",
    "beverages": "Beverage", "drink": "Beverage", "drinks": "Beverage",
    "smoothie": "Beverage", "smoothies": "Beverage",
    "shake": "Beverage", "milkshake": "Beverage",
    "cocktails": "Cocktail", "mocktail": "Cocktail",

    # --- Dish types ---
    "soups, stews and chili": "Soup",
    "vegetable soup": "Soup", "chicken soup": "Soup", "noodle soup": "Soup",
    "butternut squash soup": "Soup", "squash soup": "Soup",
    "chowder": "Soup", "chowders": "Soup",
    "stews": "Stew", "chili": "Stew", "chilli": "Stew",
    "salads": "Salad",
    "pastas": "Pasta",
    "pizzas": "Pizza",
    "curries": "Curry",
    "stir fry": "Stir-Fry", "stir fries": "Stir-Fry", "stir-fries": "Stir-Fry",
    "sandwiches": "Sandwich",
    "breads": "Bread", "yeast bread": "Bread", "quick bread": "Bread",

    # --- Cooking methods ---
    "baking": "Baked", "baked/roasted": "Baked",
    "roast": "Baked", "roasted": "Baked",
    "barbecue": "Grilled", "barbeque": "Grilled", "bbq": "Grilled",
    "grill": "Grilled", "grilling": "Grilled",
    "air fryer recipes": "Air Fryer", "air-fryer": "Air Fryer",
    "slow cooker": "Slow Cooker", "crockpot": "Slow Cooker",
    "crock pot": "Slow Cooker",
    "one-pot": "One-Pot", "one pot": "One-Pot",
    "no-cook": "No Cook", "raw": "No Cook",

    # --- Dietary ---
    "gluten free": "Gluten-Free",
    "dairy free": "Dairy-Free",
    "veggie": "Vegetarian",
    "low carb": "Low Carb",
    "high protein": "High Protein",
    "ketogenic": "Keto",

    # --- Convenience ---
    "budget": "Budget-Friendly", "cheap": "Budget-Friendly",
    "budget friendly": "Budget-Friendly", "inexpensive": "Budget-Friendly",
    "easy": "Quick", "quick & easy": "Quick", "quick and easy": "Quick",
    "30 minute meal": "30-Minute Meal", "30-minute meals": "30-Minute Meal",
    "make ahead": "Meal Prep", "make-ahead": "Meal Prep",
    "batch cooking": "Meal Prep", "batch cook": "Meal Prep",

    # --- Cuisines ---
    "southern": "American",
    "middle-eastern": "Middle Eastern",

    # --- Other ---
    "goodhealth": "Healthy", "healthy diet plan": "Healthy",
    "good for you": "Healthy", "healthy recipes": "Healthy",
}


def canonicalize_one(raw):
    """Map a single raw tag to its canonical form, or None to drop it."""
    key = str(raw).strip().lower()
    if not key:
        return None
    if key in _CANON_BY_LOWER:
        return _CANON_BY_LOWER[key]
    return TAG_ALIASES.get(key)


def canonicalize_tags(tags, enforce_single_meal_type=True):
    """Return a de-duplicated, canonical tag list.

    Drops anything that is neither a canonical tag (case-insensitive) nor a
    known alias. Order of the first occurrence is preserved. When
    ``enforce_single_meal_type`` is set, at most one of the five required meal
    types is kept (the first seen) — the model's own save()/clean() handles
    *adding* a meal type when none remains, so this function never invents one.
    """
    if not tags:
        return []

    result = []
    seen = set()
    for raw in tags:
        canon = canonicalize_one(raw)
        if canon and canon not in seen:
            seen.add(canon)
            result.append(canon)

    if enforce_single_meal_type:
        meal_types = [t for t in result if t in REQUIRED_MEAL_TYPES]
        if len(meal_types) > 1:
            keep = meal_types[0]
            result = [
                t for t in result
                if t not in REQUIRED_MEAL_TYPES or t == keep
            ]

    return result
