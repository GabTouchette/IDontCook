import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages smart selection and usage tracking for chatbot quick options.
///
/// Selection strategy:
///   - 80% of shown slots → frequency-weighted random from all options
///     (options used more often have a higher chance of appearing).
///   - 20% of shown slots → pure random from options not already selected
///     (ensures discovery of less-used options).
class QuickOptionsService {
  static const _prefsKey = 'cookbot_quick_options_usage';

  // ── Persistence ─────────────────────────────────────────────────────

  static Future<Map<String, int>> _loadUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveUsage(Map<String, int> usage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(usage));
  }

  /// Increments the usage count for [optionText] and persists it.
  static Future<void> trackUsage(String optionText) async {
    final usage = await _loadUsage();
    usage[optionText] = (usage[optionText] ?? 0) + 1;
    await _saveUsage(usage);
  }

  // ── Smart selection ──────────────────────────────────────────────────

  /// Returns [count] options from [allOptions] using the 80/20 strategy.
  ///
  /// The 80% "frequent" bucket uses weighted-random selection so that
  /// options the user has clicked more often surface more reliably, while
  /// still allowing any option to appear.  The 20% "random" bucket picks
  /// uniformly from whatever is left, adding serendipity.
  static Future<List<Map<String, dynamic>>> getSmartOptions(
    List<Map<String, dynamic>> allOptions,
    int count,
  ) async {
    if (allOptions.isEmpty) return [];
    final effectiveCount = min(count, allOptions.length);

    final usage = await _loadUsage();
    final rng = Random();

    final pool = List<Map<String, dynamic>>.from(allOptions);
    final selected = <Map<String, dynamic>>[];

    final randomSlots = max(1, (effectiveCount * 0.2).round());
    final frequentSlots = effectiveCount - randomSlots;

    // ── Frequent slots: weighted random ──
    for (int i = 0; i < frequentSlots && pool.isNotEmpty; i++) {
      final weights =
          pool.map((o) => (usage[o['text'] as String] ?? 0) + 1).toList();
      final totalWeight = weights.fold<int>(0, (a, b) => a + b);
      var pick = rng.nextInt(totalWeight);
      int idx = 0;
      for (; idx < weights.length - 1; idx++) {
        pick -= weights[idx];
        if (pick < 0) break;
      }
      selected.add(pool.removeAt(idx));
    }

    // ── Random slots: uniform random from remainder ──
    pool.shuffle(rng);
    for (int i = 0; i < randomSlots && pool.isNotEmpty; i++) {
      selected.add(pool.removeAt(0));
    }

    selected.shuffle(rng);
    return selected;
  }
}
