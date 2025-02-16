// Helper function to round the quantity to the nearest 0.125
double roundToNearestEighth(double quantity) {
  return (quantity / 0.125).round() * 0.125;
}

// Helper function to adjust the ingredient quantities based on new servings
double adjustQuantityForServings(
    double quantity, int baseServings, int newServings) {
  double adjustedQuantity = quantity * (newServings / baseServings);
  return roundToNearestEighth(adjustedQuantity);
}

// Helper function to format the adjusted quantity as a string
String formatQuantity(double quantity) {
  double roundedQuantity = (quantity / 0.125).round() * 0.125;

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
