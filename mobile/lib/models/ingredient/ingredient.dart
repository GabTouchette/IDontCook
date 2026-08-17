import 'package:freezed_annotation/freezed_annotation.dart';

part 'ingredient.freezed.dart';
part 'ingredient.g.dart';

@freezed
class Ingredient with _$Ingredient {
  const factory Ingredient({
    int? id,
    String? name,
    double? quantity,
    String? unit,
    // Preserved raw amount string for imported rows that never got a numeric
    // quantity (e.g. "pinch of", "2 tbsp"). Used as a display fallback so the
    // UI never fabricates a "1". See resolveIngredientDisplay in functions.dart.
    @JsonKey(name: 'quantity_unit') String? quantityUnit,
    String? preparation,
    List<String>? substitutes,
    Map<String, dynamic>? nutrition,
    int? canonical, // The canonical ID from backend
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}
