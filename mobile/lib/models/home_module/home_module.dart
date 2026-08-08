import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';

part 'home_module.freezed.dart';

/// A home-feed module — plan §1.2 (LOCKED contract).
///
/// ```json
/// {
///   "id": "hero-812",
///   "module_type": "hero_suggestion | cook_again | friend_post |
///                   meal_plan_nudge | grocery_shortcut | chat_prompt |
///                   explore_rail | event_card | mood_question",
///   "reason": "why you're seeing this",
///   "payload": { ...type-specific }
/// }
/// ```
///
/// JSON handling is hand-written because the payload discriminator
/// (`module_type`) lives outside the `payload` object. Unknown module types
/// (or malformed known payloads) parse into [UnknownModulePayload] — never
/// throw (forward-compat rule).
@Freezed(fromJson: false, toJson: false)
class HomeModule with _$HomeModule {
  const HomeModule._();

  const factory HomeModule({
    required String id,
    required String moduleType,
    @Default('') String reason,
    @Default(UnknownModulePayload()) ModulePayload payload,
  }) = _HomeModule;

  factory HomeModule.fromJson(Map<String, dynamic> json) {
    final moduleType = json['module_type'] as String? ?? '';
    final rawPayload =
        (json['payload'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};

    ModulePayload payload;
    try {
      switch (moduleType) {
        case 'hero_suggestion':
          payload = HeroSuggestionPayload.fromJson(rawPayload);
          break;
        case 'cook_again':
          payload = CookAgainPayload.fromJson(rawPayload);
          break;
        case 'friend_post':
          payload = FriendPostPayload.fromJson(rawPayload);
          break;
        case 'meal_plan_nudge':
          payload = MealPlanNudgePayload.fromJson(rawPayload);
          break;
        case 'grocery_shortcut':
          payload = GroceryShortcutPayload.fromJson(rawPayload);
          break;
        case 'chat_prompt':
          payload = ChatPromptPayload.fromJson(rawPayload);
          break;
        case 'explore_rail':
          payload = ExploreRailPayload.fromJson(rawPayload);
          break;
        case 'event_card':
          payload = EventCardPayload.fromJson(rawPayload);
          break;
        case 'mood_question':
          payload = MoodQuestionPayload.fromJson(rawPayload);
          break;
        default:
          payload = UnknownModulePayload(raw: rawPayload);
      }
    } catch (_) {
      // Malformed payload for a known type — degrade gracefully instead of
      // breaking the whole feed/message.
      payload = UnknownModulePayload(raw: rawPayload);
    }

    return HomeModule(
      id: json['id'] as String? ?? '',
      moduleType: moduleType,
      reason: json['reason'] as String? ?? '',
      payload: payload,
    );
  }

  /// True when this app version has a typed payload (and renderer) for
  /// [moduleType].
  bool get isKnownType => payload is! UnknownModulePayload;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'module_type': moduleType,
        'reason': reason,
        'payload': payload.toJson(),
      };
}
