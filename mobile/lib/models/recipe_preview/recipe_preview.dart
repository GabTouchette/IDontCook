import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';

part 'recipe_preview.freezed.dart';
part 'recipe_preview.g.dart';

@freezed
class RecipePreview with _$RecipePreview {
  const factory RecipePreview({
    required int id,
    required String title,
    String? description,
    int? preparation_time,
    int? cooking_time,
    String? thumbnail_url,
    List<String>? tags,
    bool? is_favorite,
    bool? is_saved,
    int? ingredients_count,
    DateTime? last_visited_at,
  }) = _RecipePreview;

  factory RecipePreview.fromJson(Map<String, dynamic> json) =>
      _$RecipePreviewFromJson(json);

  factory RecipePreview.fromRecipe(Recipe recipe) {
    return RecipePreview(
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      preparation_time: recipe.preparation_time,
      cooking_time: recipe.cooking_time,
      thumbnail_url: recipe.thumbnail_url,
      tags: recipe.tags != null ? List<String>.from(recipe.tags!) : null,
      is_favorite: recipe.is_favorite,
      last_visited_at: recipe.last_visited_at,
      ingredients_count: recipe.ingredients.length,
      is_saved: recipe.is_saved,
    );
  }
}
