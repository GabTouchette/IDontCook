import 'package:freezed_annotation/freezed_annotation.dart';
import 'ingredient.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    @Default(0) int id,
    @Default("") String title,
    @Default([]) List<Ingredient> ingredients,
    @Default([]) List<String> instructions,
    int? cooking_time,
    int? preparation_time,
    List<String>? tags,
    String? description,
    String? image_url,
    String? notes,
    DateTime? created_at,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}
