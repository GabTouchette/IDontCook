import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_view_mode.freezed.dart';

@freezed
class RecipeViewMode with _$RecipeViewMode {
  const factory RecipeViewMode.normal() = Normal;
  const factory RecipeViewMode.preview() = Preview;
  const factory RecipeViewMode.savedRecipe() = SavedRecipe;
}
