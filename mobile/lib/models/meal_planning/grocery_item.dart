class GroceryItem {
  final String name;
  final String? unit;
  final double quantity;
  final bool purchased;

  GroceryItem({
    required this.name,
    this.unit,
    required this.quantity,
    this.purchased = false,
  });

  GroceryItem copyWith({String? name, String? unit, double? quantity, bool? purchased}) {
    return GroceryItem(
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      purchased: purchased ?? this.purchased,
    );
  }
}
