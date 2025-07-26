import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

part 'paginated_recipes.freezed.dart';
part 'paginated_recipes.g.dart';

@freezed
class PaginatedRecipes with _$PaginatedRecipes {
  const factory PaginatedRecipes({
    required int count,
    required List<RecipePreview> results,
    String? next,
  }) = _PaginatedRecipes;

  factory PaginatedRecipes.fromJson(Map<String, dynamic> json) =>
      _$PaginatedRecipesFromJson(json);
}
