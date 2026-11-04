from __future__ import annotations

from typing import Dict, List, Tuple

from .models import MealPlan
from recipes.ingredient_normalizer import normalize_name_and_prep

# Unit normalization lives in grocery.units (shared with grocery.aggregator);
# see docs/plans/grocery-bag-implementation.md §3.4. Kept under the old private
# names here so the rest of this module is unchanged.
from grocery.units import normalize_unit as _normalize_unit, round_qty as _round_qty


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
    # Prefetch ingredients + nutrition + canonical to reduce queries
    planned = (
        meal_plan.planned_meals.select_related("recipe")
        .prefetch_related(
            "recipe__ingredients__nutrition_data",
            "recipe__ingredients__canonical",
        )
    )

    # key -> accumulator
    # key = (identity, unit_class, unit_label)
    # identity: ("ci", canonical_id) when the line resolved to a canonical
    #   ingredient (merge on the concept, not the string), else ("name", name)
    # unit_class: mass/volume/count
    acc: Dict[Tuple[Tuple[str, object], str, str], Dict] = {}

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
            nut_norm = None
            try:
                if getattr(ing, "nutrition_data", None):
                    nut_norm = getattr(ing.nutrition_data, "normalized_name", None)
            except Exception:
                nut_norm = None

            # Prefer the cached nutrition name when present; otherwise normalize raw.
            # (The canonical concept, when resolved, overrides this below.)
            preferred = (nut_norm or raw_name)
            name, _prep = normalize_name_and_prep(preferred)

            # Merge on the canonical concept when the line resolved to one — this
            # unifies "scallions"/"green onion", EN/FR variants, etc. that string
            # normalization alone would leave as separate rows.
            canonical = getattr(ing, "canonical", None)
            if canonical is not None:
                name = canonical.canonical_name_en or name
                identity: Tuple[str, object] = ("ci", canonical.id)
            else:
                identity = ("name", name)

            unit_class, unit_label, factor = _normalize_unit(getattr(ing, "unit", None))

            qty = getattr(ing, "quantity", None)
            try:
                qty_val = float(qty) if qty is not None else None
            except Exception:
                qty_val = None

            key = (identity, unit_class, unit_label)

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
