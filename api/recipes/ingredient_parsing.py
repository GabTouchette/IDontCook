"""Shared ingredient-line parsing.

Historically the bulk importers (``import_merged_recipes``, ``import_allrecipes``)
only ever populated the combined ``quantity_unit`` string ("2 tbsp (30 ml)") and
left the numeric ``Ingredient.quantity`` / ``Ingredient.unit`` fields NULL. The
API serializer only exposes the numeric fields, so the parsed amount never
reached the app and every line rendered as "1 <ingredient>".

This module centralises the parse so the importer and the one-off backfill
command produce identical results:

    "2 tbsp (30 ml) miso"                 -> qty=2.0,  unit="tbsp", name="miso"
    "1/2 lb (225 g) mushrooms, sliced"    -> qty=0.5,  unit="lb",   name="mushrooms", prep="sliced"
    "1 large cauliflower, cut into florets"-> qty=1.0, unit="",     name="large cauliflower", prep="cut into florets"
    "salt to taste"                        -> qty=None, unit="",     name="salt to taste"
    "pinch of salt"                        -> qty=None, unit="pinch",name="salt"

Units are emitted in the lowercase spellings that ``nutrition_service`` already
understands (see ``_convert_to_grams``), so backfilled rows become eligible for
nutrition calculation too.
"""

import re

# Unicode vulgar fractions -> decimal value.
_UNICODE_FRACTIONS = {
    '½': 0.5, '¼': 0.25, '¾': 0.75,
    '⅓': 1 / 3, '⅔': 2 / 3,
    '⅕': 0.2, '⅖': 0.4, '⅗': 0.6, '⅘': 0.8,
    '⅙': 1 / 6, '⅚': 5 / 6,
    '⅛': 0.125, '⅜': 0.375, '⅝': 0.625, '⅞': 0.875,
}
_UNICODE_FRACTION_CLASS = ''.join(_UNICODE_FRACTIONS.keys())

# Recognised unit words. Order matters only for readability; matching is anchored
# and word-boundaried. Kept broad on purpose — anything not listed stays in the
# name rather than being mis-parsed as a unit.
_UNIT_WORDS = (
    'tbsp', 'tbsps', 'tablespoon', 'tablespoons',
    'tsp', 'tsps', 'teaspoon', 'teaspoons',
    'cup', 'cups',
    'lb', 'lbs', 'pound', 'pounds',
    'oz', 'ounce', 'ounces',
    'g', 'gram', 'grams',
    'kg', 'kilogram', 'kilograms',
    'mg', 'milligram', 'milligrams',
    'ml', 'milliliter', 'milliliters', 'millilitre', 'millilitres',
    'l', 'liter', 'liters', 'litre', 'litres',
    'clove', 'cloves',
    'pinch', 'pinches',
    'dash', 'dashes',
    'can', 'cans',
    'slice', 'slices',
    'piece', 'pieces', 'pc',
    'sprig', 'sprigs',
    'bunch', 'bunches',
    'stalk', 'stalks',
    'head', 'heads',
    'ear', 'ears',
    'leaf', 'leaves',
    'stick', 'sticks',
    'handful', 'handfuls',
)

# Normalise a few variant spellings to the canonical form nutrition_service keys
# on. Anything not in this map is passed through lowercased.
_UNIT_CANONICAL = {
    'tbsps': 'tbsp', 'tablespoon': 'tbsp', 'tablespoons': 'tbsp',
    'tsps': 'tsp', 'teaspoon': 'tsp', 'teaspoons': 'tsp',
    'pc': 'piece',
}

# A leading quantity: mixed number ("1 1/2"), slash fraction ("3/4"), a unicode
# fraction (optionally preceded by a whole number, "1½"), or a plain
# integer/decimal ("2", "2.5", "2,5"). Ranges ("1-2", "1 to 2") are handled by
# taking the first value.
_QTY_RE = re.compile(
    r'^\s*('
    r'\d+\s+\d+\s*/\s*\d+'                       # 1 1/2
    r'|\d+\s*/\s*\d+'                            # 3/4
    r'|\d+\s*[' + _UNICODE_FRACTION_CLASS + r']'  # 1½
    r'|[' + _UNICODE_FRACTION_CLASS + r']'        # ½
    r'|\d+(?:[.,]\d+)?'                          # 2 / 2.5 / 2,5
    r')'
)

_UNIT_RE = re.compile(
    r'^\s*(' + '|'.join(sorted(_UNIT_WORDS, key=len, reverse=True)) + r')\b\.?',
    re.IGNORECASE,
)
_PAREN_RE = re.compile(r'^\s*\([^)]*\)')
# A range separator right after the first quantity: "1-2 cups", "1 to 2 cups".
_RANGE_RE = re.compile(
    r'^\s*(?:-|–|to\b)\s*(?:\d+(?:[.,]\d+)?|\d+\s*/\s*\d+|[' + _UNICODE_FRACTION_CLASS + r'])',
    re.IGNORECASE,
)


def parse_quantity(token):
    """Parse a single leading quantity token to a float, or None.

    Handles integers, decimals (dot or comma), slash fractions, mixed numbers,
    and unicode vulgar fractions ("1½", "½").
    """
    if not token:
        return None
    token = token.strip()

    # Bare unicode fraction, or whole+unicode ("1½").
    m = re.match(r'^(\d+)?\s*([' + _UNICODE_FRACTION_CLASS + r'])$', token)
    if m:
        whole = int(m.group(1)) if m.group(1) else 0
        return whole + _UNICODE_FRACTIONS[m.group(2)]

    # Mixed number "1 1/2".
    m = re.match(r'^(\d+)\s+(\d+)\s*/\s*(\d+)$', token)
    if m:
        whole, num, den = int(m.group(1)), int(m.group(2)), int(m.group(3))
        return whole + (num / den) if den else float(whole)

    # Slash fraction "3/4".
    m = re.match(r'^(\d+)\s*/\s*(\d+)$', token)
    if m:
        num, den = int(m.group(1)), int(m.group(2))
        return num / den if den else None

    # Plain integer/decimal, comma-as-decimal tolerated.
    try:
        return float(token.replace(',', '.'))
    except ValueError:
        return None


def _canonical_unit(word):
    if not word:
        return ''
    w = word.lower().rstrip('.')
    return _UNIT_CANONICAL.get(w, w)


def parse_ingredient(text):
    """Parse a raw ingredient line into its parts.

    Returns a dict with keys: ``quantity`` (float|None), ``unit`` (str),
    ``name`` (str), ``preparation`` (str), ``quantity_unit`` (str, the recombined
    amount+unit+metric-paren prefix) and ``original_text`` (the trimmed input).
    """
    original_text = (text or '').strip()
    rest = original_text
    qty_unit_parts = []
    quantity = None
    unit = ''

    # 1) Leading quantity.
    m = _QTY_RE.match(rest)
    if m:
        qty_token = m.group(1)
        quantity = parse_quantity(qty_token)
        qty_unit_parts.append(qty_token.strip())
        rest = rest[m.end():]

        # Absorb a range upper bound so it doesn't leak into the name; keep the
        # lower bound as the quantity (predictable, never overstates amounts).
        rm = _RANGE_RE.match(rest)
        if rm:
            qty_unit_parts.append(rm.group(0).strip())
            rest = rest[rm.end():]

        # 2) Unit word and/or a metric parenthetical, in whichever order they
        # appear ("2 tbsp (30 ml)" vs "2 (30 ml) tbsp"). Try up to twice.
        for _ in range(2):
            um = _UNIT_RE.match(rest)
            pm = _PAREN_RE.match(rest)
            if um:
                if not unit:
                    unit = _canonical_unit(um.group(1))
                qty_unit_parts.append(um.group(0).strip())
                rest = rest[um.end():]
            elif pm:
                qty_unit_parts.append(pm.group(0).strip())
                rest = rest[pm.end():]
            else:
                break

    quantity_unit = ' '.join(p for p in qty_unit_parts if p).strip()
    name_and_prep = rest.strip() if quantity_unit else original_text

    # A stray leading metric parenthetical can survive when there was no leading
    # quantity (e.g. name imported as "(225 g) bacon"); strip it from the name.
    pm = _PAREN_RE.match(name_and_prep)
    if pm and not quantity_unit:
        name_and_prep = name_and_prep[pm.end():].strip()

    if ',' in name_and_prep:
        name, _, preparation = name_and_prep.partition(',')
        name = name.strip()
        preparation = preparation.strip()
    else:
        name = name_and_prep.strip()
        preparation = ''

    return {
        'quantity': quantity,
        'unit': unit,
        'name': name,
        'preparation': preparation,
        'quantity_unit': quantity_unit,
        'original_text': original_text,
    }
