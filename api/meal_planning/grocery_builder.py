from __future__ import annotations

from typing import Dict, List, Tuple
import re

from .models import MealPlan
from recipes.ingredient_normalizer import normalize_name_and_prep


# --- Unit normalization maps ---
_MASS_TO_G = {
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

_VOLUME_TO_ML = {
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

_COUNT_UNITS = {
    "": "unit",
    "unit": "unit",
    "units": "unit",
    "piece": "piece",
    "pieces": "piece",
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


# Common name synonyms to help collapse variants
_NAME_SYNONYMS = {
    "scallion": "green onion",
    "scallions": "green onion",
    "spring onion": "green onion",
    "cilantro": "coriander",
    "coriander leaves": "coriander",
    "bell pepper": "capsicum",
    "bell peppers": "capsicum",
    "powdered sugar": "icing sugar",
    "confectioners sugar": "icing sugar",
    "bicarbonate of soda": "baking soda",
    "bicarb soda": "baking soda",
}


_DESCRIPTORS = {
    "fresh",
    "dried",
    "minced",
    "chopped",
    "sliced",
    "optional",
    "to taste",
    "ground",
}


def _strip_parentheses(text: str) -> str:
    return re.sub(r"\([^)]*\)", "", text or "").strip()


def _normalize_name(name: str, usda_name: str | None, nutrition_normalized: str | None) -> str:
    # Priority: nutrition_data.normalized_name > usda_name > provided name
    base = (nutrition_normalized or usda_name or name or "").strip().lower()
    base = _strip_parentheses(base)
    # Remove commas and extra punctuation
    base = re.sub(r"[,:;]\s*", " ", base)
    # Remove common descriptors tokens
    toks = [t for t in re.split(r"\s+", base) if t]
    toks = [t for t in toks if t not in _DESCRIPTORS]
    base = " ".join(toks).strip()
    # Apply simple plural normalization
    if base.endswith("es") and len(base) > 4:
        base = base[:-2]
    elif base.endswith("s") and len(base) > 3:
        base = base[:-1]
    # Synonyms
    base = _NAME_SYNONYMS.get(base, base)
    return base


def _normalize_unit(unit: str | None) -> Tuple[str, str, float]:
    """
    Normalize a unit to one of:
    - mass in grams: returns ("mass", "g", factor_to_apply)
    - volume in milliliters: returns ("volume", "ml", factor_to_apply)
    - count/custom: returns ("count", canonical_unit_name, 1.0)
    Unknown becomes count with the raw unit (or 'unit').
    """
    raw = (unit or "").strip().lower()
    raw = raw.replace(".", "")
    raw = raw.replace("fl. oz", "fl oz")
    raw = raw.replace("fluid oz", "fl oz")

    if raw in _MASS_TO_G:
        return ("mass", "g", _MASS_TO_G[raw])
    if raw in _VOLUME_TO_ML:
        return ("volume", "ml", _VOLUME_TO_ML[raw])

    # try common alias without spaces
    if raw.replace(" ", "") in _VOLUME_TO_ML:
        return ("volume", "ml", _VOLUME_TO_ML[raw.replace(" ", "")])

    # Fallback: treat as count-ish unit and unify plural
    canonical = _COUNT_UNITS.get(raw, raw or "unit")
    return ("count", canonical, 1.0)


def _round_qty(q: float) -> float:
    # Round to 2 decimals, strip -0.0
    val = round(float(q or 0), 2)
    return 0.0 if abs(val) < 1e-9 else val


def build_grocery_list(meal_plan: MealPlan) -> List[Dict]:
    """
    Aggregate and normalize ingredients across all planned meals in the given meal plan.

    Output shape: List[{
        'name': str,           # canonical ingredient name
        'quantity': float|None,# summed in g or ml when convertible; else raw sum per unit
        'unit': str|None,      # 'g' | 'ml' | count-ish canonical unit | None
        'variants': List[str], # original names seen (deduped, optional)
    }]
    """
    # Prefetch ingredients + nutrition to reduce queries
    planned = (
        meal_plan.planned_meals.select_related("recipe")
        .prefetch_related("recipe__ingredients__nutrition_data")
    )

    # key -> accumulator
    # key = (name, unit_class, unit_label)
    # unit_class: mass/volume/count
    acc: Dict[Tuple[str, str, str], Dict] = {}

    for pm in planned:
        recipe = pm.recipe
        if not recipe:
            continue
        # Determine scaling factor based on servings selected for this planned meal
        try:
            pm_servings = int(getattr(pm, "servings", 1) or 1)
        except Exception:
            pm_servings = 1
        try:
            base_servings = int(getattr(recipe, "servings", 0) or 0)
        except Exception:
            base_servings = 0
        if base_servings <= 0:
            base_servings = 1  # assume recipe quantities are for 1 serving when unknown
        scale = max(1, pm_servings) / float(base_servings)
        for ing in recipe.ingredients.all():
            raw_name = (getattr(ing, "name", None) or "").strip()
            usda_name = getattr(ing, "usda_name", None)
            nut_norm = None
            try:
                if getattr(ing, "nutrition_data", None):
                    nut_norm = getattr(ing.nutrition_data, "normalized_name", None)
            except Exception:
                nut_norm = None

            # Prefer normalized nutrition name/usda when present; otherwise normalize raw
            preferred = (nut_norm or usda_name or raw_name)
            name, _prep = normalize_name_and_prep(preferred)
            unit_class, unit_label, factor = _normalize_unit(getattr(ing, "unit", None))

            qty = getattr(ing, "quantity", None)
            try:
                qty_val = float(qty) if qty is not None else None
            except Exception:
                qty_val = None

            key = (name, unit_class, unit_label)

            entry = acc.get(key)
            if not entry:
                entry = {
                    "name": name,
                    "quantity": 0.0 if qty_val is not None else None,
                    "unit": unit_label,
                    "variants": set(),
                }
                acc[key] = entry

            if raw_name:
                entry["variants"].add(raw_name.lower())

            # Aggregate quantities when possible
            if qty_val is not None:
                if unit_class in ("mass", "volume"):
                    entry["quantity"] = (entry["quantity"] or 0.0) + (qty_val * scale * factor)
                    entry["unit"] = unit_label  # canonical g/ml
                else:
                    # count/custom units: only aggregate when unit_label matches
                    entry["quantity"] = (entry["quantity"] or 0.0) + (qty_val * scale)
            else:
                # if no numeric quantity, leave as None and keep one line item
                entry["quantity"] = None

    # Finalize list and convert variant set to list
    results: List[Dict] = []
    for (_name, _cls, _u), item in acc.items():
        out = dict(item)
        out["variants"] = sorted(list(out.get("variants", [])))
        if out.get("quantity") is not None:
            out["quantity"] = _round_qty(out["quantity"])
        results.append(out)

    # Sort by name then unit
    results.sort(key=lambda x: (x.get("name") or "", x.get("unit") or ""))
    return results
