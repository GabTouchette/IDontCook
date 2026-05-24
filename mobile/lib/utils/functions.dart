// ---------------------------------------------------------------------------
// Unit vocabulary — every word that can appear as a unit in ingredient text.
// Used by resolveIngredientDisplay to detect and strip unit tokens from names.
// ---------------------------------------------------------------------------
const _knownUnits = {
  'tablespoon', 'tablespoons', 'tbsp', 'tbs', 'tb',
  'teaspoon', 'teaspoons', 'tsp',
  'cup', 'cups',
  'fluid ounce', 'fluid ounces', 'fl oz',
  'ounce', 'ounces', 'oz',
  'pound', 'pounds', 'lb', 'lbs',
  'gram', 'grams', 'g',
  'kilogram', 'kilograms', 'kg',
  'milligram', 'milligrams', 'mg',
  'milliliter', 'milliliters', 'millilitre', 'millilitres', 'ml',
  'liter', 'liters', 'litre', 'litres', 'l',
  'clove', 'cloves',
  'piece', 'pieces', 'pc',
  'slice', 'slices',
  'pinch', 'pinches',
  'handful', 'handfuls',
  'bunch', 'bunches',
  'can', 'cans',
  'package', 'packages', 'packet', 'packets', 'pkg', 'pkt',
  'stick', 'sticks',
  'head', 'heads',
  'sprig', 'sprigs',
  'drop', 'drops',
  'quart', 'quarts', 'qt',
  'pint', 'pints', 'pt',
  'gallon', 'gallons', 'gal',
  'centiliter', 'centiliters', 'cl',
};

// Multi-word units checked before single-word (order matters: longest first).
const _multiWordUnits = ['fluid ounces', 'fluid ounce', 'fl oz'];

// Regex: matches a leading quantity expression (integer, decimal, slash-fraction,
// unicode fraction, or mixed number like "1 1/2").
final _leadingQtyRe = RegExp(
  r'^((?:\d+\s+)?\d+/\d+|[½¼¾⅓⅔⅛⅜⅝⅞]|\d+(?:\.\d+)?)\s*',
);

/// Parses a quantity string ("1/2", "¾", "1 1/2", "2.5") to double.
/// Returns null if unparseable.
double? _parseFraction(String s) {
  s = s.trim();
  const unicode = <String, double>{
    '½': 0.5, '¼': 0.25, '¾': 0.75,
    '⅓': 1 / 3, '⅔': 2 / 3,
    '⅛': 0.125, '⅜': 0.375, '⅝': 0.625, '⅞': 0.875,
  };
  if (unicode.containsKey(s)) return unicode[s];
  final d = double.tryParse(s);
  if (d != null) return d;
  // slash fraction e.g. "3/4"
  final slash = s.split('/');
  if (slash.length == 2) {
    final n = double.tryParse(slash[0].trim());
    final den = double.tryParse(slash[1].trim());
    if (n != null && den != null && den != 0) return n / den;
  }
  // mixed number e.g. "1 1/2"
  final space = s.indexOf(' ');
  if (space != -1) {
    final whole = double.tryParse(s.substring(0, space).trim());
    final frac = _parseFraction(s.substring(space + 1).trim());
    if (whole != null && frac != null) return whole + frac;
  }
  return null;
}

/// Collapses consecutive duplicate tokens (case-insensitive).
String _deduplicateTokens(String text) {
  final tokens = text.trim().split(RegExp(r'\s+'));
  if (tokens.isEmpty) return text;
  final out = <String>[];
  for (final t in tokens) {
    if (out.isEmpty || t.toLowerCase() != out.last.toLowerCase()) out.add(t);
  }
  return out.join(' ');
}

/// Attempts to strip a leading unit word from [text].
/// Returns `(remainder, unitWord)` — if no unit found both are unchanged/empty.
(String, String) _stripLeadingUnitToken(String text) {
  final lower = text.toLowerCase();
  // Multi-word units first
  for (final u in _multiWordUnits) {
    if (lower.startsWith('$u ') || lower == u) {
      return (text.substring(u.length).trim(), u);
    }
  }
  // Single-word: grab first space-delimited token, strip trailing punctuation
  final spaceIdx = text.indexOf(' ');
  final firstWord = (spaceIdx == -1 ? text : text.substring(0, spaceIdx))
      .toLowerCase()
      .replaceAll(RegExp(r'[.,;()\[\]]'), '');
  if (_knownUnits.contains(firstWord) && spaceIdx != -1) {
    // Only strip if something follows (don't eat the ingredient name)
    return (text.substring(spaceIdx + 1).trim(), firstWord);
  }
  return (text, '');
}

/// Resolves a clean (qty, unit, name) triple for display from raw ingredient
/// fields, handling common data quality issues:
///
///  • Full string in name ("2 tablespoons butter", qty=0, unit="")
///    → extracts qty=2, unit="tablespoon", name="butter"
///
///  • Unit leaked into name ("cup flour", qty=1, unit="cup")
///    → strips leading "cup" from name → "flour"
///
///  • Redundant qty in name ("1 garlic", qty=1, unit="clove")
///    → strips leading "1" from name → "garlic"
///
///  • Clean data ("garlic", qty=2, unit="clove") → unchanged
///
/// Also scales qty by servings and abbreviates units.
({String qty, String unit, String name}) resolveIngredientDisplay({
  required double dbQuantity,
  required String dbUnit,
  required String dbName,
  required double servings,
  required double baseServings,
}) {
  double qty = dbQuantity;
  String unit = dbUnit.trim();
  String name = dbName.trim();

  if (qty == 0 && unit.isEmpty) {
    // ── Case: no structured data — try to extract from the name string ──────
    final qtyMatch = _leadingQtyRe.firstMatch(name);
    if (qtyMatch != null) {
      final parsed = _parseFraction(qtyMatch.group(1)!);
      if (parsed != null && parsed > 0) {
        qty = parsed;
        name = name.substring(qtyMatch.end).trim();
      }
    }
    final (stripped, extractedUnit) = _stripLeadingUnitToken(name);
    if (extractedUnit.isNotEmpty && stripped.isNotEmpty) {
      unit = extractedUnit;
      name = stripped;
    }
  } else {
    // ── Case: DB has qty and/or unit — strip redundant tokens from name ──────

    // Strip a leading number from name when qty is already known
    final qtyMatch = _leadingQtyRe.firstMatch(name);
    if (qtyMatch != null && qtyMatch.end < name.length) {
      // Only strip when followed by more text (avoid eating "2% milk")
      final afterNum = name.substring(qtyMatch.end).trim();
      if (afterNum.isNotEmpty) name = afterNum;
    }

    // Strip a leading unit word from name if it matches the known unit
    if (unit.isNotEmpty) {
      final (stripped, extractedUnit) = _stripLeadingUnitToken(name);
      if (extractedUnit.isNotEmpty) {
        final abbrevExtracted = abbreviateUnit(extractedUnit.toLowerCase());
        final abbrevKnown = abbreviateUnit(unit.toLowerCase());
        if (abbrevExtracted == abbrevKnown) name = stripped;
      }
    } else {
      // Unit field is empty — grab unit from name if present
      final (stripped, extractedUnit) = _stripLeadingUnitToken(name);
      if (extractedUnit.isNotEmpty && stripped.isNotEmpty) {
        unit = extractedUnit;
        name = stripped;
      }
    }
  }

  // Final cleanup
  name = _deduplicateTokens(name).toLowerCase();
  if (name.isEmpty) name = dbName.toLowerCase().trim(); // fallback to original

  final adjusted = adjustQuantityForServings(qty, baseServings, servings);
  final rawQty = formatQuantity(adjusted);
  return (
    qty: rawQty.isEmpty ? '1' : rawQty,
    unit: unit.isNotEmpty ? abbreviateUnit(unit.toLowerCase()) : '',
    name: name,
  );
}

/// Maps common long unit names to their standard abbreviations for display.
/// Handles singular, plural, and already-abbreviated forms.
String abbreviateUnit(String unit) {
  const Map<String, String> _abbreviations = {
    // tablespoon
    'tablespoon': 'tbsp',
    'tablespoons': 'tbsp',
    'tbsp': 'tbsp',
    'tbs': 'tbsp',
    'tb': 'tbsp',
    // teaspoon
    'teaspoon': 'tsp',
    'teaspoons': 'tsp',
    'tsp': 'tsp',
    // cup
    'cup': 'cup',
    'cups': 'cup',
    'cup(s)': 'cup',
    // fluid ounce
    'fluid ounce': 'fl oz',
    'fluid ounces': 'fl oz',
    'fl oz': 'fl oz',
    // ounce
    'ounce': 'oz',
    'ounces': 'oz',
    'oz': 'oz',
    // pound
    'pound': 'lb',
    'pounds': 'lb',
    'lb': 'lb',
    'lbs': 'lb',
    // gram
    'gram': 'g',
    'grams': 'g',
    'g': 'g',
    // kilogram
    'kilogram': 'kg',
    'kilograms': 'kg',
    'kg': 'kg',
    // milligram
    'milligram': 'mg',
    'milligrams': 'mg',
    'mg': 'mg',
    // milliliter
    'milliliter': 'ml',
    'milliliters': 'ml',
    'millilitre': 'ml',
    'millilitres': 'ml',
    'ml': 'ml',
    // liter
    'liter': 'L',
    'liters': 'L',
    'litre': 'L',
    'litres': 'L',
    'l': 'L',
    // clove
    'clove': 'clove',
    'cloves': 'clove',
    'clove(s)': 'clove',
    // piece
    'piece': 'pc',
    'pieces': 'pc',
    'piece(s)': 'pc',
    // slice
    'slice': 'slice',
    'slices': 'slice',
    'slice(s)': 'slice',
    // pinch
    'pinch': 'pinch',
    'pinches': 'pinch',
    // handful
    'handful': 'hdfl',
    'handfuls': 'hdfl',
    // bunch
    'bunch': 'bunch',
    'bunches': 'bunch',
    'bunch(es)': 'bunch',
    // can
    'can': 'can',
    'cans': 'can',
    'can(s)': 'can',
    // package / packet
    'package': 'pkg',
    'packages': 'pkg',
    'packet': 'pkt',
    'packets': 'pkt',
    // stick
    'stick': 'stick',
    'sticks': 'stick',
    'stick(s)': 'stick',
    // head
    'head': 'head',
    'heads': 'head',
    // sprig
    'sprig': 'sprig',
    'sprigs': 'sprig',
    // drop
    'drop': 'drop',
    'drops': 'drop',
    // quart
    'quart': 'qt',
    'quarts': 'qt',
    'qt': 'qt',
    // pint
    'pint': 'pt',
    'pints': 'pt',
    'pt': 'pt',
    // gallon
    'gallon': 'gal',
    'gallons': 'gal',
    'gal': 'gal',
    // centiliter
    'centiliter': 'cl',
    'centiliters': 'cl',
    'cl': 'cl',
  };

  final lower = unit.trim().toLowerCase();
  return _abbreviations[lower] ?? unit.trim();
}

/// Collapses consecutive duplicate tokens in a pre-assembled ingredient line.
String sanitizeIngredientLine(String line) => _deduplicateTokens(line);

// Helper function to round the quantity to the nearest 0.125
double roundToNearestEighth(double quantity) {
  return (quantity / 0.125).round() * 0.125;
}

// Helper function to adjust the ingredient quantities based on new servings
double adjustQuantityForServings(
    double quantity, double baseServings, double newServings) {
  double adjustedQuantity = quantity * (newServings / baseServings);
  return roundToNearestEighth(adjustedQuantity);
}

// Helper function to format the adjusted quantity as a string
String formatQuantity(double quantity) {
  double roundedQuantity = (quantity / 0.125).round() * 0.125;

  if (roundedQuantity == 0) {
    return "";
  }
  final fraction = (roundedQuantity - roundedQuantity.toInt()) * 1000;
  final intValue =
      roundedQuantity.toInt() > 0 ? roundedQuantity.toInt().toString() : "";

  switch (fraction.toInt()) {
    case 125:
      return "$intValue 1/8";
    case 250:
      return "$intValue 1/4";
    case 375:
      return "$intValue 3/8";
    case 500:
      return "$intValue 1/2";
    case 625:
      return "$intValue 5/8";
    case 750:
      return "$intValue 3/4";
    case 875:
      return "$intValue 7/8";
    default:
      if (roundedQuantity == roundedQuantity.toInt()) {
        return roundedQuantity.toInt().toString();
      } else {
        return roundedQuantity.toStringAsFixed(3);
      }
  }
}
