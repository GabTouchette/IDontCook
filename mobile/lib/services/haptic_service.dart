import 'package:flutter/services.dart';

/// Centralised haptic feedback service.
/// All intensity levels are named semantically so the intent is clear at call
/// sites, and the `enabled` flag lets a future Settings toggle silence haptics
/// app-wide without touching individual call sites.
class HapticService {
  static bool enabled = true;

  // ── Micro-interactions ──────────────────────────────────────────────────────
  /// Tab switches, checkbox toggles, counter increments, chip selection.
  static Future<void> selectionClick() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  // ── Secondary actions ───────────────────────────────────────────────────────
  /// Search clear, filter open/close, nav arrow taps.
  static Future<void> lightImpact() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  // ── Primary actions ─────────────────────────────────────────────────────────
  /// Save recipe, send message, follow, post submit.
  static Future<void> mediumImpact() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  // ── Destructive actions ─────────────────────────────────────────────────────
  /// Delete recipe, logout, confirm destructive dialog.
  static Future<void> heavyImpact() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  // ── Outcome notifications ───────────────────────────────────────────────────
  static Future<void> notificationSuccess() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> notificationWarning() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> notificationError() async {
    if (!enabled) return;
    await HapticFeedback.vibrate();
  }
}
