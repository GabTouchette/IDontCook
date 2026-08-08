import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';

part 'module_payloads.freezed.dart';
part 'module_payloads.g.dart';

/// Base type for every `module.payload` shape — plan §1.2 (LOCKED contract).
///
/// One concrete class per `module_type`; [UnknownModulePayload] is the
/// forward-compat fallback for module types this app version doesn't know.
abstract class ModulePayload {
  Map<String, dynamic> toJson();
}

/// Fallback payload for unknown `module_type` values (plan §1.2
/// forward-compat rule: silently skipped, never an error).
class UnknownModulePayload implements ModulePayload {
  const UnknownModulePayload({this.raw = const <String, dynamic>{}});

  /// The raw payload JSON, preserved for round-tripping.
  final Map<String, dynamic> raw;

  @override
  Map<String, dynamic> toJson() => raw;
}

/// `hero_suggestion` → `{ "recipe": RecipeSummary, "tagline": str }`
@freezed
class HeroSuggestionPayload
    with _$HeroSuggestionPayload
    implements ModulePayload {
  const factory HeroSuggestionPayload({
    required RecipeSummary recipe,
    @Default('') String tagline,
  }) = _HeroSuggestionPayload;

  factory HeroSuggestionPayload.fromJson(Map<String, dynamic> json) =>
      _$HeroSuggestionPayloadFromJson(json);
}

/// `cook_again` → `{ "recipe": RecipeSummary, "saved_at": iso8601 }`
@freezed
class CookAgainPayload with _$CookAgainPayload implements ModulePayload {
  const factory CookAgainPayload({
    required RecipeSummary recipe,
    DateTime? saved_at,
  }) = _CookAgainPayload;

  factory CookAgainPayload.fromJson(Map<String, dynamic> json) =>
      _$CookAgainPayloadFromJson(json);
}

/// Author sub-object of `friend_post`:
/// `{"id": int, "username": str, "avatar_url": str|null}`
@freezed
class PostAuthor with _$PostAuthor {
  const factory PostAuthor({
    required int id,
    required String username,
    String? avatar_url,
  }) = _PostAuthor;

  factory PostAuthor.fromJson(Map<String, dynamic> json) =>
      _$PostAuthorFromJson(json);
}

/// `friend_post` → `{ "post_id": int, "author": {...}, "recipe":
/// RecipeSummary|null, "preview_text": str, "created_at": iso8601 }`
@freezed
class FriendPostPayload with _$FriendPostPayload implements ModulePayload {
  const factory FriendPostPayload({
    required int post_id,
    required PostAuthor author,
    RecipeSummary? recipe,
    @Default('') String preview_text,
    DateTime? created_at,
  }) = _FriendPostPayload;

  factory FriendPostPayload.fromJson(Map<String, dynamic> json) =>
      _$FriendPostPayloadFromJson(json);
}

/// `meal_plan_nudge` → `{ "week_start": iso8601-date, "planned_days": int,
/// "cta": str }`
@freezed
class MealPlanNudgePayload
    with _$MealPlanNudgePayload
    implements ModulePayload {
  const factory MealPlanNudgePayload({
    @Default('') String week_start,
    @Default(0) int planned_days,
    @Default('') String cta,
  }) = _MealPlanNudgePayload;

  factory MealPlanNudgePayload.fromJson(Map<String, dynamic> json) =>
      _$MealPlanNudgePayloadFromJson(json);
}

/// `grocery_shortcut` → `{ "item_count": int, "cta": str }`
@freezed
class GroceryShortcutPayload
    with _$GroceryShortcutPayload
    implements ModulePayload {
  const factory GroceryShortcutPayload({
    @Default(0) int item_count,
    @Default('') String cta,
  }) = _GroceryShortcutPayload;

  factory GroceryShortcutPayload.fromJson(Map<String, dynamic> json) =>
      _$GroceryShortcutPayloadFromJson(json);
}

/// `chat_prompt` → `{ "prompt_text": str }` — tapping sends `prompt_text`
/// as a user chat message.
@freezed
class ChatPromptPayload with _$ChatPromptPayload implements ModulePayload {
  const factory ChatPromptPayload({
    @Default('') String prompt_text,
  }) = _ChatPromptPayload;

  factory ChatPromptPayload.fromJson(Map<String, dynamic> json) =>
      _$ChatPromptPayloadFromJson(json);
}

/// `explore_rail` → `{ "title": str, "recipes": [RecipeSummary] }`
@freezed
class ExploreRailPayload with _$ExploreRailPayload implements ModulePayload {
  const factory ExploreRailPayload({
    @Default('') String title,
    @Default(<RecipeSummary>[]) List<RecipeSummary> recipes,
  }) = _ExploreRailPayload;

  factory ExploreRailPayload.fromJson(Map<String, dynamic> json) =>
      _$ExploreRailPayloadFromJson(json);
}

/// `event_card` → `{ "event_slug": str, "title": str, "body": str,
/// "image_url": str|null, "cta": str|null, "recipes": [RecipeSummary] }`
@freezed
class EventCardPayload with _$EventCardPayload implements ModulePayload {
  const factory EventCardPayload({
    @Default('') String event_slug,
    @Default('') String title,
    @Default('') String body,
    String? image_url,
    String? cta,
    @Default(<RecipeSummary>[]) List<RecipeSummary> recipes,
  }) = _EventCardPayload;

  factory EventCardPayload.fromJson(Map<String, dynamic> json) =>
      _$EventCardPayloadFromJson(json);
}

/// One option of a `mood_question`:
/// `{"mood": MoodEnum, "label": str, "emoji": str}`
///
/// [mood] keeps the raw wire string; [moodValue] resolves it to a [Mood]
/// (null for unknown moods — forward-compat, callers should skip those).
@freezed
class MoodOption with _$MoodOption {
  const MoodOption._();

  const factory MoodOption({
    @Default('') String mood,
    @Default('') String label,
    @Default('') String emoji,
  }) = _MoodOption;

  factory MoodOption.fromJson(Map<String, dynamic> json) =>
      _$MoodOptionFromJson(json);

  Mood? get moodValue => Mood.fromWire(mood);
}

/// `mood_question` → `{ "question": str, "options": [MoodOption] }`
@freezed
class MoodQuestionPayload
    with _$MoodQuestionPayload
    implements ModulePayload {
  const factory MoodQuestionPayload({
    @Default('') String question,
    @Default(<MoodOption>[]) List<MoodOption> options,
  }) = _MoodQuestionPayload;

  factory MoodQuestionPayload.fromJson(Map<String, dynamic> json) =>
      _$MoodQuestionPayloadFromJson(json);
}
