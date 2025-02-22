import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/models/user/user.dart';
import '../ingredient/ingredient.dart';

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
    int? servings,
    List<String>? tags,
    String? description,
    String? image_url,
    String? thumbnail_url,
    String? notes,
    bool? is_favorite,
    DateTime? created_at,
    User? created_by,
    DateTime? last_visited_at,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}
