from __future__ import annotations

import re
from typing import Tuple, Optional

# Curated multi-word descriptor phrases to remove entirely
_PHRASE_DESCRIPTORS = [
    'freshly ground',
    'extra virgin',
    'low sodium',
    'reduced sodium',
    'room temperature',
    'for serving',
    'for garnish',
    'to serve',
]

# Single-word descriptors/adjectives often not needed in the canonical name
_WORD_DESCRIPTORS = {
    'fresh', 'frozen', 'canned', 'jarred', 'organic', 'unsalted', 'salted',
    'boneless', 'skinless', 'lean', 'thick', 'thin', 'large', 'small', 'medium',
    'whole', 'divided', 'optional', 'packed', 'softened', 'melted', 'drained', 'rinsed',
    'peeled', 'seeded', 'cored', 'trimmed', 'stemmed', 'zested', 'juiced',
    'minced', 'chopped', 'diced', 'sliced', 'shredded', 'grated', 'crushed', 'cubed', 'deseeded',
}

# Words that look like descriptors but should be retained with certain nouns
_CONTEXT_EXCEPTIONS = {
    'ground': {'beef', 'pork', 'turkey', 'chicken', 'lamb'},  # keep in these combos
}

# Conservative synonyms to unify common variants
_SYNONYMS = {
    'scallion': 'green onion',
    'scallions': 'green onion',
    'spring onion': 'green onion',
    'spring onions': 'green onion',
    'garbanzo bean': 'chickpea',
    'garbanzo beans': 'chickpeas',
    'chick pea': 'chickpea',
    'chick peas': 'chickpeas',
    'bell peppers': 'bell pepper',
    'powdered sugar': 'icing sugar',
    'confectioners sugar': 'icing sugar',
}


_PARENS_RE = re.compile(r"\([^)]*\)")
_PUNCT_RE = re.compile(r"[,:;]\s*")
_SPACE_RE = re.compile(r"\s+")


def _strip_parentheses(text: str) -> str:
    return _PARENS_RE.sub("", text or "").strip()


def _split_prep_tokens(tokens):
    name_tokens = []
    prep_tokens = []
    i = 0
    while i < len(tokens):
        # phrase descriptors (2-word lookahead)
        if i + 1 < len(tokens):
            joined = f"{tokens[i]} {tokens[i+1]}"
            if joined in _PHRASE_DESCRIPTORS:
                prep_tokens.append(joined)
                i += 2
                continue
        t = tokens[i]
        # context exception for words like 'ground'
        if t in _CONTEXT_EXCEPTIONS and i + 1 < len(tokens):
            nxt = tokens[i + 1]
            if nxt in _CONTEXT_EXCEPTIONS[t]:
                name_tokens.append(t)
                i += 1
                continue
        if t in _WORD_DESCRIPTORS:
            prep_tokens.append(t)
            i += 1
            continue
        name_tokens.append(t)
        i += 1

    return name_tokens, prep_tokens


def normalize_name_and_prep(raw_name: str) -> Tuple[str, Optional[str]]:
    """Return (canonical_name, preparation) from a raw ingredient name/phrase.
    - Removes parentheticals and punctuation
    - Splits out descriptor/prep tokens
    - Applies conservative synonyms
    - Normalizes plurals (basic)
    """
    if not raw_name:
        return '', None

    base = (raw_name or '').strip().lower()
    base = _strip_parentheses(base)
    base = _PUNCT_RE.sub(' ', base)
    tokens = [t for t in _SPACE_RE.split(base) if t]

    name_tokens, prep_tokens = _split_prep_tokens(tokens)
    name = ' '.join(name_tokens).strip()

    # simple plural normalization
    if name.endswith('es') and len(name) > 4:
        name = name[:-2]
    elif name.endswith('s') and len(name) > 3 and not name.endswith('ss'):
        name = name[:-1]

    # apply synonyms on full name when exact match
    name = _SYNONYMS.get(name, name)
    if not name:
        # fallback if stripped too much
        name = (raw_name or '').strip().lower()

    prep = ' '.join(prep_tokens).strip() if prep_tokens else None
    return name, (prep or None)
