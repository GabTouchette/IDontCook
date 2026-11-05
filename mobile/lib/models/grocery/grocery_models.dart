/// Models for the Grocery Bag feature.
///
/// Mirrors the backend `ShoppableLine` contract
/// (api/docs/plans/grocery-bag-implementation.md §3.3) and the bag endpoints
/// (§4.2). Plain classes with `fromJson`, matching the meal_planning models.

class GroceryAmount {
  final double? value;
  final String unit;
  final String dimension; // mass | volume | count

  GroceryAmount({this.value, required this.unit, required this.dimension});

  factory GroceryAmount.fromJson(Map<String, dynamic> json) => GroceryAmount(
        value: (json['value'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? '',
        dimension: json['dimension'] as String? ?? 'count',
      );
}

class GroceryComponent {
  final double? quantity;
  final String unit;

  GroceryComponent({this.quantity, required this.unit});

  factory GroceryComponent.fromJson(Map<String, dynamic> json) =>
      GroceryComponent(
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? '',
      );
}

class GrocerySource {
  final int? recipeId;
  final String title;
  final double? quantity;
  final String unit;

  GrocerySource({
    this.recipeId,
    required this.title,
    this.quantity,
    required this.unit,
  });

  factory GrocerySource.fromJson(Map<String, dynamic> json) => GrocerySource(
        recipeId: json['recipe_id'] as int?,
        title: json['title'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? '',
      );
}

class ShoppableLine {
  final String key; // stable override key: "ci:<id>" or "name:<norm>"
  final int? conceptId;
  final String name;
  final String? category;
  final GroceryAmount amount;
  final double? approxG;
  final List<GroceryComponent> components;
  final List<GrocerySource> sources;
  final double? stapleScore;
  final double? matchConfidence;
  final bool needsConfirmation;
  final bool checked;
  final bool inPantry;
  final List<String> variants;

  ShoppableLine({
    required this.key,
    this.conceptId,
    required this.name,
    this.category,
    required this.amount,
    this.approxG,
    this.components = const [],
    this.sources = const [],
    this.stapleScore,
    this.matchConfidence,
    this.needsConfirmation = false,
    this.checked = false,
    this.inPantry = false,
    this.variants = const [],
  });

  factory ShoppableLine.fromJson(Map<String, dynamic> json) => ShoppableLine(
        key: json['key'] as String,
        conceptId: json['concept_id'] as int?,
        name: json['name'] as String? ?? '',
        category: json['category'] as String?,
        amount: GroceryAmount.fromJson(
            (json['amount'] as Map).cast<String, dynamic>()),
        approxG: (json['approx_g'] as num?)?.toDouble(),
        components: ((json['components'] as List?) ?? [])
            .map((c) => GroceryComponent.fromJson((c as Map).cast<String, dynamic>()))
            .toList(),
        sources: ((json['sources'] as List?) ?? [])
            .map((s) => GrocerySource.fromJson((s as Map).cast<String, dynamic>()))
            .toList(),
        stapleScore: (json['staple_score'] as num?)?.toDouble(),
        matchConfidence: (json['match_confidence'] as num?)?.toDouble(),
        needsConfirmation: json['needs_confirmation'] as bool? ?? false,
        checked: json['checked'] as bool? ?? false,
        inPantry: json['in_pantry'] as bool? ?? false,
        variants: ((json['variants'] as List?) ?? [])
            .map((v) => v.toString())
            .toList(),
      );

  /// Distinct recipe titles this line came from (for provenance chips).
  List<String> get recipeTitles {
    final seen = <String>{};
    final out = <String>[];
    for (final s in sources) {
      if (s.title.isNotEmpty && seen.add(s.title)) out.add(s.title);
    }
    return out;
  }

  /// Human-readable primary amount, e.g. "412 g", "740 ml", "5 clove".
  String get displayAmount {
    final v = amount.value;
    if (v == null) return amount.unit.isEmpty ? '' : amount.unit;
    final num shown = v == v.roundToDouble() ? v.round() : v;
    final unit = amount.unit;
    return unit.isEmpty ? '$shown' : '$shown $unit';
  }

  /// Residual components rendered as a trailing hint, e.g. "+ 1 tbsp".
  String get displayComponents {
    if (components.isEmpty) return '';
    return components.map((c) {
      final q = c.quantity;
      final shown =
          q == null ? '' : (q == q.roundToDouble() ? '${q.round()} ' : '$q ');
      return '$shown${c.unit}';
    }).join(', ');
  }
}

class BagRecipe {
  final int id; // GroceryBagRecipe id
  final int recipeId;
  final String title;
  final int? baseServings;
  final int servings;
  final String? image;

  BagRecipe({
    required this.id,
    required this.recipeId,
    required this.title,
    this.baseServings,
    required this.servings,
    this.image,
  });

  factory BagRecipe.fromJson(Map<String, dynamic> json) => BagRecipe(
        id: json['id'] as int,
        recipeId: json['recipe_id'] as int,
        title: json['title'] as String? ?? '',
        baseServings: json['base_servings'] as int?,
        servings: json['servings'] as int? ?? 1,
        image: json['image'] as String?,
      );
}

class GroceryBag {
  final List<BagRecipe> recipes;
  final List<ShoppableLine> items;
  final List<ShoppableLine> hiddenItems;
  final int removedCount;
  final int hiddenCount;

  GroceryBag({
    this.recipes = const [],
    this.items = const [],
    this.hiddenItems = const [],
    this.removedCount = 0,
    this.hiddenCount = 0,
  });

  factory GroceryBag.fromJson(Map<String, dynamic> json) => GroceryBag(
        recipes: ((json['recipes'] as List?) ?? [])
            .map((r) => BagRecipe.fromJson((r as Map).cast<String, dynamic>()))
            .toList(),
        items: ((json['items'] as List?) ?? [])
            .map((i) => ShoppableLine.fromJson((i as Map).cast<String, dynamic>()))
            .toList(),
        hiddenItems: ((json['hidden_items'] as List?) ?? [])
            .map((i) => ShoppableLine.fromJson((i as Map).cast<String, dynamic>()))
            .toList(),
        removedCount: json['removed_count'] as int? ?? 0,
        hiddenCount: json['hidden_count'] as int? ?? 0,
      );

  bool get isEmpty => recipes.isEmpty;
  int get itemCount => items.length;
}
