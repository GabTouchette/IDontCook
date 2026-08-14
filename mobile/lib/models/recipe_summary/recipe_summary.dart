import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_summary.freezed.dart';
part 'recipe_summary.g.dart';

/// Compact recipe reference — plan §1.1 (LOCKED contract).
///
/// `RecipeSummary = { "id": int, "title": str, "image_url": str|null,
/// "total_time": int|null, "calories": int|null, "tags": [str] }`
@freezed
class RecipeSummary with _$RecipeSummary {
  const factory RecipeSummary({
    required int id,
    required String title,
    String? image_url,
    int? total_time,
    int? calories,
    @Default(<String>[]) List<String> tags,
    // Whether this recipe belongs to the current user (their own saved/created
    // recipe) vs. a catalog find. Optional/defaulted for forward-compat with
    // older payloads that don't send it.
    @Default(false) bool is_owned,
  }) = _RecipeSummary;

  factory RecipeSummary.fromJson(Map<String, dynamic> json) =>
      _$RecipeSummaryFromJson(json);
}
