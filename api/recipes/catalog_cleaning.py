"""Deterministic canonical-name cleaning + grouping for catalog hygiene.

The seeded catalog is full of raw ingredient *lines* masquerading as canonical
concepts ("garlic clove finely", "egg lightly beaten", "garlic cloves with a
microplane grater"). This module reduces a messy name to its base ingredient and
decides whether that reduction is trustworthy; the ``clean_canonical_catalog``
command uses it to merge rows deterministically and routes whatever stays
ambiguous to Claude. Kept import-light and side-effect-free so it unit-tests
offline.
"""

from __future__ import annotations

import re

from .ingredient_normalizer import (
    _USDA_PREP_WORDS,
    _WORD_DESCRIPTORS,
    clean_for_usda,
    normalize_name_and_prep,
)

# Stop/cruft words that appear in recipe lines but never belong in a canonical
# ingredient name. Combined with the normalizer's prep/descriptor sets below.
_CRUFT_WORDS = {
    "with", "a", "an", "the", "to", "into", "and", "or", "of", "for", "plus",
    "more", "taste", "at", "about", "approximately", "approx", "such", "as",
    "like", "your", "choice", "preferably", "room", "temperature", "separated",
    "pressed", "beaten", "grater", "microplane", "sliver", "slivers", "wedge",
    "wedges", "pieces", "piece", "strips", "strip", "chunks", "chunk", "halves",
    "garnish", "serving", "serve", "needed", "if", "each", "very", "well",
    "plenty", "some", "any", "other", "optional", "divided", "packed",
    # adverbs of preparation (can't blanket-strip -ly words — "pork belly")
    "lightly", "slightly", "freshly", "evenly", "firmly", "thickly", "gently",
    "loosely", "generously", "coarsely",
    "cut", "smashed", "pressed", "cracked",
}

_STRIP_WORDS = _USDA_PREP_WORDS | _WORD_DESCRIPTORS | _CRUFT_WORDS

# Repair the old seed plural-corruption ("olives"->"oliv", "cloves"->"clov") that
# predates the normalizer fix and is baked into stored canonical names.
_DEMANGLE = {
    "oliv": "olive", "clov": "clove", "noodl": "noodle", "cooki": "cookie",
    "squar": "square", "wedg": "wedge", "piec": "piece", "cub": "cube",
    "cherri": "cherry", "grap": "grape", "granul": "granule", "patti": "patty",
    "flak": "flake", "slic": "slice", "berri": "berry", "pastri": "pastry",
}

_SPLIT_RE = re.compile(r"[\s/]+")


def demangle(text: str) -> str:
    """Repair seed-corrupted plural stems token-by-token."""
    return " ".join(_DEMANGLE.get(w, w) for w in (text or "").split())


def deterministic_clean(name: str) -> str:
    """Reduce a messy canonical name to its base ingredient (best effort).

    Drops anything after the first comma, strips prep/descriptor/cruft words,
    then applies the shared normalizer (synonyms + plural). Returns '' when
    nothing meaningful survives.
    """
    if not name:
        return ""
    base = demangle(clean_for_usda(name))  # lowercased, comma-trimmed, prep/unit words gone
    tokens = [t for t in _SPLIT_RE.split(base) if t and t not in _STRIP_WORDS]
    cleaned = " ".join(tokens).strip()
    if not cleaned:
        return ""
    norm, _prep = normalize_name_and_prep(cleaned)
    return demangle((norm or cleaned).strip().lower())


def is_ambiguous(name: str, cleaned: str) -> bool:
    """True when the deterministic cleaning can't be trusted → route to Claude.

    Ambiguous when nothing survived, when leftover cruft/stop words remain, or
    when the result is still long enough (>=3 words) to likely be a phrase rather
    than an ingredient. Real two-word ingredients ("olive oil", "soy sauce",
    "chicken breast") pass as clean.
    """
    if not cleaned:
        return True
    tokens = cleaned.split()
    if any(t in _STRIP_WORDS for t in tokens):
        return True
    if len(tokens) >= 3:
        return True
    return False
