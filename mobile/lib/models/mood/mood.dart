import 'package:freezed_annotation/freezed_annotation.dart';

/// Mood taxonomy — plan §1.3 (LOCKED contract).
///
/// `MoodEnum = "rushed" | "ambitious" | "cooking_for_someone" | "comfort" |
/// "healthy" | "surprise_me"`
enum Mood {
  @JsonValue('rushed')
  rushed('rushed'),
  @JsonValue('ambitious')
  ambitious('ambitious'),
  @JsonValue('cooking_for_someone')
  cookingForSomeone('cooking_for_someone'),
  @JsonValue('comfort')
  comfort('comfort'),
  @JsonValue('healthy')
  healthy('healthy'),
  @JsonValue('surprise_me')
  surpriseMe('surprise_me');

  const Mood(this.wireValue);

  /// The exact string sent to / received from the API.
  final String wireValue;

  /// Tolerant lookup: returns null for unknown or null wire values
  /// (forward-compat rule — never throw on unknown enum values).
  static Mood? fromWire(String? value) {
    if (value == null) return null;
    for (final mood in Mood.values) {
      if (mood.wireValue == value) return mood;
    }
    return null;
  }
}
