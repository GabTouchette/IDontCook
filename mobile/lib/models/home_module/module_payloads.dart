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

/// One sale item inside a `deals_rail`, tagged with which nearby store it's
/// from: `{ "name": str, "name_alt": str|null, "brand": str, "price": str|null,
///    "price_value": num|null, "discount": int|null, "image_url": str|null,
///    "valid_to": iso8601|null, "merchant": str, "distance_m": int|null }`
@freezed
class DealItem with _$DealItem {
  const DealItem._();

  const factory DealItem({
    @Default('') String name,
    String? name_alt,
    @Default('') String brand,
    String? price,
    num? price_value,
    int? discount,
    String? image_url,
    String? valid_to,
    @Default('') String merchant,
    int? distance_m,
    num? savings,
  }) = _DealItem;

  factory DealItem.fromJson(Map<String, dynamic> json) =>
      _$DealItemFromJson(json);

  /// "800 m" / "1.2 km" — null when distance is unknown.
  String? get distanceLabel {
    final d = distance_m;
    if (d == null) return null;
    if (d < 1000) return '$d m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }

  /// "Save $3.00" — null when there's no computable saving.
  String? get savingsLabel {
    final s = savings;
    if (s == null || s <= 0) return null;
    return 'Save \$${s.toStringAsFixed(2)}';
  }

  /// "Valid until Jan 15" — null when there's no parseable end date. Flipp
  /// sends `valid_to` as a date or ISO datetime string; render it dependency-
  /// free (no `intl`) with a short month name.
  String? get validUntilLabel {
    final raw = valid_to;
    if (raw == null || raw.isEmpty) return null;
    final date = DateTime.tryParse(raw);
    if (date == null) return null;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Valid until ${months[date.month - 1]} ${date.day}';
  }
}

/// A store included in the nearby-deals pool: `{ "merchant": str,
/// "merchant_id": int, "merchant_logo": str|null, "distance_m": int|null }`.
@freezed
class DealStore with _$DealStore {
  const factory DealStore({
    @Default('') String merchant,
    @Default(0) int merchant_id,
    String? merchant_logo,
    int? distance_m,
  }) = _DealStore;

  factory DealStore.fromJson(Map<String, dynamic> json) =>
      _$DealStoreFromJson(json);
}

/// `deals_rail` → the biggest discounts pooled from the user's nearest stores.
/// `{ "state": "setup"|"loading"|"ready", "postal_code": str|null,
///    "stores": [DealStore], "total_count": int, "items": [DealItem] }`
///
/// `setup` means we have no location yet — the card prompts to enable location.
/// `loading` means the location is known but deals are still warming server-side
/// (cold cache) — the card shows a "finding deals" state and the client polls.
@freezed
class DealsRailPayload with _$DealsRailPayload implements ModulePayload {
  const DealsRailPayload._();

  const factory DealsRailPayload({
    @Default('ready') String state,
    String? postal_code,
    @Default(<DealStore>[]) List<DealStore> stores,
    @Default(0) int total_count,
    @Default(<DealItem>[]) List<DealItem> items,
  }) = _DealsRailPayload;

  factory DealsRailPayload.fromJson(Map<String, dynamic> json) =>
      _$DealsRailPayloadFromJson(json);

  bool get needsSetup => state == 'setup';

  /// Location is known but deals are still warming server-side (cold cache).
  bool get isLoading => state == 'loading';
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
class MoodQuestionPayload with _$MoodQuestionPayload implements ModulePayload {
  const factory MoodQuestionPayload({
    @Default('') String question,
    @Default(<MoodOption>[]) List<MoodOption> options,
  }) = _MoodQuestionPayload;

  factory MoodQuestionPayload.fromJson(Map<String, dynamic> json) =>
      _$MoodQuestionPayloadFromJson(json);
}
