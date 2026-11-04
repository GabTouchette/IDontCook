"""Unit normalization for grocery aggregation.

Neutral home for the mass/volume/count unit maps and the ``normalize_unit``
helper. Extracted from ``meal_planning.grocery_builder`` so both the legacy
meal-plan grocery list and the new grocery-bag aggregator share one source of
truth (see docs/plans/grocery-bag-implementation.md §3.4).
"""
from __future__ import annotations

from typing import Tuple

# --- Unit normalization maps ---
MASS_TO_G = {
    "mg": 0.001,
    "g": 1.0,
    "gram": 1.0,
    "grams": 1.0,
    "kg": 1000.0,
    "kilogram": 1000.0,
    "kilograms": 1000.0,
    "oz": 28.349523125,
    "ounce": 28.349523125,
    "ounces": 28.349523125,
    "lb": 453.59237,
    "lbs": 453.59237,
    "pound": 453.59237,
    "pounds": 453.59237,
}

VOLUME_TO_ML = {
    "ml": 1.0,
    "milliliter": 1.0,
    "milliliters": 1.0,
    "l": 1000.0,
    "liter": 1000.0,
    "liters": 1000.0,
    "tsp": 5.0,
    "teaspoon": 5.0,
    "teaspoons": 5.0,
    "tbsp": 15.0,
    "tablespoon": 15.0,
    "tablespoons": 15.0,
    "fl oz": 29.5735,
    "floz": 29.5735,
    "fluid ounce": 29.5735,
    "fluid ounces": 29.5735,
    "cup": 240.0,
    "cups": 240.0,
    "pint": 473.176,
    "pints": 473.176,
    "quart": 946.353,
    "quarts": 946.353,
    "gallon": 3785.41,
    "gallons": 3785.41,
}

COUNT_UNITS = {
    "": "unit",
    "unit": "unit",
    "units": "unit",
    "piece": "piece",
    "pieces": "piece",
    "pc": "piece",
    "pcs": "piece",
    "item": "item",
    "items": "item",
    "clove": "clove",
    "cloves": "clove",
    "slice": "slice",
    "slices": "slice",
    "can": "can",
    "cans": "can",
    "package": "package",
    "packages": "package",
    "bunch": "bunch",
    "bunches": "bunch",
    "stick": "stick",
    "sticks": "stick",
    "bag": "bag",
    "bags": "bag",
}


def normalize_unit(unit: str | None) -> Tuple[str, str, float]:
    """Normalize a unit to one of:

    - mass in grams: returns ("mass", "g", factor_to_apply)
    - volume in milliliters: returns ("volume", "ml", factor_to_apply)
    - count/custom: returns ("count", canonical_unit_name, 1.0)

    Unknown becomes count with the raw unit (or 'unit').
    """
    raw = (unit or "").strip().lower()
    raw = raw.replace(".", "")
    raw = raw.replace("fl. oz", "fl oz")
    raw = raw.replace("fluid oz", "fl oz")

    if raw in MASS_TO_G:
        return ("mass", "g", MASS_TO_G[raw])
    if raw in VOLUME_TO_ML:
        return ("volume", "ml", VOLUME_TO_ML[raw])

    # try common alias without spaces
    if raw.replace(" ", "") in VOLUME_TO_ML:
        return ("volume", "ml", VOLUME_TO_ML[raw.replace(" ", "")])

    # Fallback: treat as count-ish unit and unify plural
    canonical = COUNT_UNITS.get(raw, raw or "unit")
    return ("count", canonical, 1.0)


def round_qty(q: float | None) -> float:
    """Round to 2 decimals, stripping -0.0."""
    val = round(float(q or 0), 2)
    return 0.0 if abs(val) < 1e-9 else val
