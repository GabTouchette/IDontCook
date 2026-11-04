"""Staple-aware ordering for the Grocery Bag (Part C1).

Sorts the shoppable list so the items you're *least* likely to already have
float to the top and pantry staples sink to the bottom, and drops a tiny set of
"everyone has this" items (salt/pepper/water) entirely. See
docs/plans/grocery-bag-implementation.md §5.1.

Uses only the canonical category prior for now; per-user pantry personalization
(Part C2) layers on top of ``staple_score`` later.
"""
from __future__ import annotations

from typing import List, Tuple

# P(user already has it): 0.0 = surely need to buy (top) ... 1.0 = surely have
# (bottom). Keyed by CanonicalIngredient.category 2-letter code.
_STAPLE_SCORE_BY_CATEGORY = {
    "PR": 0.05,  # Produce
    "MS": 0.05,  # Meat & Seafood
    "BA": 0.15,  # Bakery
    "DE": 0.20,  # Dairy & Eggs
    "FR": 0.40,  # Frozen
    "BE": 0.45,  # Beverages
    "CJ": 0.60,  # Canned & Jars
    "DG": 0.70,  # Dry Goods & Pasta
    "BK": 0.80,  # Baking
    "CO": 0.90,  # Condiments & Oils
    "SP": 0.95,  # Spices
    "HO": 0.50,  # Household / Other
}
_DEFAULT_STAPLE_SCORE = 0.5

# "Assumed on hand" concepts dropped from the list (with a reveal affordance in
# the UI). Matched by normalized canonical name. Keep this short — distinct from
# the per-user pantry (C2).
_ALWAYS_HIDDEN = {"salt", "pepper", "black pepper", "water"}


def staple_score(category) -> float:
    if category and category in _STAPLE_SCORE_BY_CATEGORY:
        return _STAPLE_SCORE_BY_CATEGORY[category]
    return _DEFAULT_STAPLE_SCORE


def is_always_hidden(name) -> bool:
    return (name or "").strip().lower() in _ALWAYS_HIDDEN


def prepare_lines(lines) -> Tuple[List, int]:
    """Assign ``staple_score``, drop always-hidden items, sort least-likely first.

    Mutates each line's ``staple_score`` in place. Returns
    ``(visible_sorted, hidden_count)``. Ties break alphabetically by name.
    """
    visible = []
    hidden_count = 0
    for line in lines:
        line.staple_score = staple_score(line.category)
        if is_always_hidden(line.name):
            hidden_count += 1
            continue
        visible.append(line)
    visible.sort(key=lambda line: (line.staple_score, line.name or ""))
    return visible, hidden_count
