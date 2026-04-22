/// Cleans a fully-assembled ingredient display line:
/// 1. Collapses consecutive duplicate tokens  ("1 cup cup milk" → "1 cup milk")
/// 2. Prepends "1" when the line starts with a non-numeric token ("tbsp salt" → "1 tbsp salt")
String sanitizeIngredientLine(String line) {
  final tokens = line.trim().split(RegExp(r'\s+'));
  if (tokens.isEmpty) return line;

  // Collapse consecutive duplicates (case-insensitive)
  final deduped = <String>[];
  for (final token in tokens) {
    if (deduped.isEmpty || token.toLowerCase() != deduped.last.toLowerCase()) {
      deduped.add(token);
    }
  }

  final result = deduped.join(' ');

  // If first token is not a number/fraction, prepend "1"
  if (result.isNotEmpty &&
      !RegExp(r'^[\d½¼¾⅓⅔⅛⅜⅝⅞]').hasMatch(result)) {
    return '1 $result';
  }

  return result;
}

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
