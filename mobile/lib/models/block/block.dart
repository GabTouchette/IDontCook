import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:i_cant_cook/models/home_module/home_module.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';

part 'block.freezed.dart';
part 'block.g.dart';

/// The unit of rich content in chat messages and the home feed —
/// plan §1.1 (LOCKED contract).
///
/// ```json
/// { "block_type": "text",          "text": "string (markdown)" }
/// { "block_type": "recipe",        "recipe": <RecipeFull> }
/// { "block_type": "recipe_ref",    "recipe": <RecipeSummary> }
/// { "block_type": "recipe_update", "recipe_id": 123, "changes": {...} }
/// { "block_type": "module",        "module": <Module> }
/// ```
///
/// Forward-compat rule: an unknown (or missing) `block_type` parses into
/// [Block.unknown] via `fallbackUnion` — it never throws.
@Freezed(
  unionKey: 'block_type',
  unionValueCase: FreezedUnionCase.snake,
  fallbackUnion: 'unknown',
)
class Block with _$Block {
  /// `block_type: "text"` — markdown text.
  const factory Block.text({
    @Default('') String text,
  }) = TextBlock;

  /// `block_type: "recipe"` — a full recipe (same shape the `$$` delimiter
  /// protocol carried; parses with the existing [Recipe] model).
  const factory Block.recipe({
    required Recipe recipe,
  }) = RecipeBlock;

  /// `block_type: "recipe_ref"` — a compact reference to an existing recipe.
  const factory Block.recipeRef({
    required RecipeSummary recipe,
  }) = RecipeRefBlock;

  /// `block_type: "recipe_update"` — changed fields of an existing recipe.
  const factory Block.recipeUpdate({
    required int recipe_id,
    @Default(<String, dynamic>{}) Map<String, dynamic> changes,
  }) = RecipeUpdateBlock;

  /// `block_type: "module"` — a home-feed module card.
  const factory Block.module({
    required HomeModule module,
  }) = ModuleBlock;

  /// Fallback for unknown `block_type` values — rendered as nothing.
  const factory Block.unknown() = UnknownBlock;

  factory Block.fromJson(Map<String, dynamic> json) => _$BlockFromJson(json);
}
