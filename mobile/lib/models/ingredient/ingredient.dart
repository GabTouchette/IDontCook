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
    String? preparation,
    List<String>? substitutes,
    Map<String, dynamic>? nutrition,
    int? canonical, // The canonical ID from backend
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}
