"""
ingredient_matcher.py — Fuzzy canonical-ingredient matcher.

Maps a raw ingredient name string to the closest CanonicalIngredient entry in
the database using a simple, fast token-overlap heuristic.  No external
dependencies required (uses only the stdlib and Django ORM).

Usage:
    from recipes.ingredient_matcher import find_canonical_ingredient

    canonical = find_canonical_ingredient("fresh minced garlic cloves")
    # → <CanonicalIngredient: garlic>

    canonical = find_canonical_ingredient("poitrine de poulet")
    # → <CanonicalIngredient: chicken breast>  (if French name matches)
"""

import re
from functools import lru_cache
from typing import Optional

from .models import CanonicalIngredient
from .nutrition_service import _clean_for_usda, _PREP_WORDS


# ---------------------------------------------------------------------------
# Token helpers
# ---------------------------------------------------------------------------

def _tokenize(text: str) -> set[str]:
    """Lowercase, strip punctuation, split on whitespace.  Returns set of tokens."""
    text = text.lower()
    text = re.sub(r"[^\w\s]", " ", text)
    return set(t for t in text.split() if t and t not in _PREP_WORDS and len(t) > 1)


def _jaccard(a: set, b: set) -> float:
    """Jaccard similarity between two token sets."""
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def _overlap_coeff(query: set, candidate: set) -> float:
    """Overlap coefficient — good when candidate is longer than query."""
    if not query or not candidate:
        return 0.0
    return len(query & candidate) / min(len(query), len(candidate))


# ---------------------------------------------------------------------------
# Main matcher
# ---------------------------------------------------------------------------

def find_canonical_ingredient(
    raw_name: str,
    threshold: float = 0.4,
    language: str = "en",
) -> Optional[CanonicalIngredient]:
    """Return the best-matching CanonicalIngredient for *raw_name*, or None.

    Args:
        raw_name:   The ingredient text as it appears in the recipe (may include
                    preparation notes, quantities, etc.).
        threshold:  Minimum similarity score required to accept a match (0–1).
        language:   Preferred language for the name field to match against
                    ("en" or "fr").  Both are always compared; this just weights
                    the preferred language slightly higher.

    Returns:
        The best-matching CanonicalIngredient, or None if no candidate scores
        above *threshold*.
    """
    if not raw_name or not raw_name.strip():
        return None

    # Clean the name (remove prep words, punctuation after comma, etc.)
    cleaned = _clean_for_usda(raw_name)
    query_tokens = _tokenize(cleaned)
    if not query_tokens:
        query_tokens = _tokenize(raw_name)
    if not query_tokens:
        return None

    # --- First pass: fast DB pre-filter ---
    # Find candidates where at least one token appears in either name field.
    # Build a loose OR filter using the longest token (most selective).
    sorted_tokens = sorted(query_tokens, key=len, reverse=True)
    anchor = sorted_tokens[0]

    from django.db.models import Q
    qs = CanonicalIngredient.objects.filter(
        Q(canonical_name_en__icontains=anchor)
        | Q(canonical_name_fr__icontains=anchor)
    )

    # If no candidates found with the longest token, fall back to all tokens
    if not qs.exists():
        q = Q()
        for tok in sorted_tokens[:3]:  # limit to top-3 tokens for performance
            q |= Q(canonical_name_en__icontains=tok) | Q(canonical_name_fr__icontains=tok)
        qs = CanonicalIngredient.objects.filter(q)

    if not qs.exists():
        return None

    # --- Second pass: score each candidate ---
    best_score = -1.0
    best_obj = None

    for ci in qs:
        en_tokens = _tokenize(ci.canonical_name_en or "")
        fr_tokens = _tokenize(ci.canonical_name_fr or "")

        # Use overlap coefficient (better for multi-word queries vs single-word candidates)
        score_en = _overlap_coeff(query_tokens, en_tokens) if en_tokens else 0.0
        score_fr = _overlap_coeff(query_tokens, fr_tokens) if fr_tokens else 0.0

        # Also compute Jaccard as a tiebreaker signal
        jac_en = _jaccard(query_tokens, en_tokens)
        jac_fr = _jaccard(query_tokens, fr_tokens)

        # Weighted combination: prefer the language hint
        if language == "fr":
            score = max(score_fr * 1.1, score_en) + max(jac_fr, jac_en) * 0.1
        else:
            score = max(score_en * 1.1, score_fr) + max(jac_en, jac_fr) * 0.1

        if score > best_score:
            best_score = score
            best_obj = ci

    if best_score >= threshold:
        return best_obj
    return None


# ---------------------------------------------------------------------------
# Batch helper
# ---------------------------------------------------------------------------

def match_ingredients_to_canonical(
    ingredient_ids: list[int],
    threshold: float = 0.4,
    save: bool = True,
) -> dict[int, Optional[CanonicalIngredient]]:
    """Match a list of Ingredient PKs to their best CanonicalIngredient.

    Args:
        ingredient_ids: List of Ingredient primary keys.
        threshold:      Minimum similarity score to accept (forwarded to
                        find_canonical_ingredient).
        save:           If True, update `ingredient.canonical` and
                        `ingredient.match_confidence` in the database.

    Returns:
        Dict mapping ingredient_id → CanonicalIngredient (or None).
    """
    from .models import Ingredient

    ingredients = Ingredient.objects.filter(pk__in=ingredient_ids)
    results: dict[int, Optional[CanonicalIngredient]] = {}

    for ing in ingredients:
        raw = ing.usda_name or ing.name or ""
        lang = ing.language or "en"
        ci = find_canonical_ingredient(raw, threshold=threshold, language=lang)
        results[ing.pk] = ci

        if save:
            changed = False
            if ci and ing.canonical_id != ci.pk:
                ing.canonical = ci
                ing.match_confidence = None  # will be computed below
                changed = True
            if changed:
                ing.save(update_fields=["canonical", "match_confidence"])

    return results
