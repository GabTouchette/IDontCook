import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/mood/mood.dart';

/// Shared visual constants for block renderers, matching the existing
/// chatbot cards (sharp corners, thin outline, lime accent).
const Color kBlockAccent = Color(0xFFCAFF00);
const Color kBlockAccentInk = Color(0xFF0A0A0A);

/// Vertical breathing room between feed items (greeting, module cards).
/// Applied once in `home_page.dart`'s block list — individual block widgets
/// should not add their own outer margin, to avoid doubling the gap.
const double kBlockFeedGap = 16.0;

/// Standard bordered container used by block cards/bubbles.
BoxDecoration blockCardDecoration(BuildContext context,
    {double outlineOpacity = 0.15}) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    border: Border.all(
      color: Theme.of(context)
          .colorScheme
          .outline
          .withValues(alpha: outlineOpacity),
      width: 1.5,
    ),
  );
}

/// Lighter-weight pill decoration for tappable chips (mood options, chat
/// prompts) — a deliberate departure from the sharp-cornered card language,
/// used only where the design calls for something visibly less "boxed".
BoxDecoration blockPillDecoration(
  BuildContext context, {
  double outlineOpacity = 0.25,
  Color? fill,
}) {
  return BoxDecoration(
    color: fill ?? Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(999),
    border: Border.all(
      color: Theme.of(context)
          .colorScheme
          .outline
          .withValues(alpha: outlineOpacity),
      width: 1.5,
    ),
  );
}

/// Coarse, dependency-free relative time string ("just now", "3h ago",
/// "5d ago") for module cards (`cook_again.saved_at`,
/// `friend_post.created_at`). Returns '' for null input.
String relativeTimeLabel(DateTime? from, {DateTime? now}) {
  if (from == null) return '';
  final reference = now ?? DateTime.now();
  final diff = reference.difference(from);
  if (diff.isNegative || diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final weeks = diff.inDays ~/ 7;
  if (weeks < 5) return '${weeks}w ago';
  final months = diff.inDays ~/ 30;
  if (months < 12) return '${months}mo ago';
  final years = diff.inDays ~/ 365;
  return '${years}y ago';
}

/// Time-of-day icon, used to give the feed's greeting a little personality.
/// Falls back to a neutral nightlight icon when [hour] is out of range
/// (never happens for `DateTime.now().hour`, but keeps this total).
///
/// Renders via Material Icons rather than emoji — emoji glyphs (e.g. ☀️/🌤️)
/// aren't reliably present in this app's font stack (Space Grotesk has no
/// emoji glyphs, and there's no color-emoji fallback configured), which was
/// rendering as tofu/garbage characters. Icons are the app's existing visual
/// vocabulary (see `navbar.dart`, `ai_chatbot_page.dart`) and render
/// everywhere.
IconData dayPartIcon({int? hour}) {
  final h = hour ?? DateTime.now().hour;
  if (h >= 5 && h < 11) return Icons.wb_sunny_outlined;
  if (h >= 11 && h < 17) return Icons.wb_cloudy_outlined;
  if (h >= 17 && h < 21) return Icons.wb_twilight;
  return Icons.nightlight_outlined;
}

/// Best-effort icon for a module's "why you're seeing this" reason line,
/// picked from a few common keyword families. Returns null when [reason] is
/// empty (callers should skip the badge entirely in that case) — otherwise
/// always returns an icon (falls back to a sparkle for anything
/// unrecognized).
IconData? reasonIcon(String reason) {
  if (reason.isEmpty) return null;
  final lower = reason.toLowerCase();
  const families = <String, List<String>>{
    'timer': ['quick', 'fast', 'minute', 'busy', 'rushed'],
    'eco': ['healthy', 'light', 'veg', 'salad', 'nutriti'],
    'soup': ['comfort', 'cozy', 'warm', 'hearty'],
    'savings': ['budget', 'cheap', 'affordable'],
    'autorenew': ['leftover', 'again', 'pantry', 'use up'],
    'celebration': ['weekend', 'celebrat', 'party', 'special'],
    'fire': ['trend', 'popular', 'hot'],
  };
  for (final entry in families.entries) {
    if (entry.value.any(lower.contains)) {
      switch (entry.key) {
        case 'timer':
          return Icons.timer_outlined;
        case 'eco':
          return Icons.eco_outlined;
        case 'soup':
          return Icons.soup_kitchen_outlined;
        case 'savings':
          return Icons.savings_outlined;
        case 'autorenew':
          return Icons.autorenew;
        case 'celebration':
          return Icons.celebration_outlined;
        case 'fire':
          return Icons.local_fire_department_outlined;
      }
    }
  }
  return Icons.auto_awesome_outlined;
}

/// Icon representing a [Mood] option — used by the mood-selection pills and
/// by the persistent "mood chosen" indicator, in place of the server-sent
/// `emoji` string on each option (which has the same tofu-glyph problem as
/// [dayPartIcon]/[reasonIcon] and is intentionally ignored for rendering).
IconData moodIcon(Mood mood) {
  switch (mood) {
    case Mood.rushed:
      return Icons.timer_outlined;
    case Mood.ambitious:
      return Icons.local_fire_department_outlined;
    case Mood.cookingForSomeone:
      return Icons.favorite_outline;
    case Mood.comfort:
      return Icons.soup_kitchen_outlined;
    case Mood.healthy:
      return Icons.eco_outlined;
    case Mood.surpriseMe:
      return Icons.casino_outlined;
  }
}

/// Accent color for a [Mood], paired with [moodIcon]. Used to tint the
/// mood-selection pills (icon + outline when unselected, fill when selected)
/// so the quick-pill row reads as a colorful palette of intents rather than a
/// monochrome list. Colors are mid-saturation so they stay legible against
/// both light and dark surfaces.
Color moodColor(Mood mood) {
  switch (mood) {
    case Mood.rushed:
      return const Color(0xFFF59E0B); // amber
    case Mood.ambitious:
      return const Color(0xFFEF4444); // red
    case Mood.cookingForSomeone:
      return const Color(0xFFEC4899); // rose
    case Mood.comfort:
      return const Color(0xFFF97316); // orange
    case Mood.healthy:
      return const Color(0xFF22C55E); // green
    case Mood.surpriseMe:
      return const Color(0xFF8B5CF6); // violet
  }
}

/// Readable foreground (ink) color to lay over a filled [background] chip —
/// dark ink on light accents, white on dark ones — so selected mood pills
/// keep their label/icon legible regardless of the accent's brightness.
Color onColorInk(Color background) {
  return background.computeLuminance() > 0.55
      ? const Color(0xFF0A0A0A)
      : Colors.white;
}

/// Shared type treatment for the small "why you're seeing this" reason/
/// subtext line used across `hero_suggestion`, `cook_again`, `friend_post`,
/// and other module cards. Centralized so the feed reads as one coherent
/// type system rather than each card inventing its own size/weight/color —
/// a touch more letter-spacing and a slightly warmer weight than a plain
/// caption, so it reads as an editorial aside rather than a debug label.
TextStyle reasonTextStyle(BuildContext context, {Color? color}) {
  final onSurface = Theme.of(context).colorScheme.onSurface;
  return GoogleFonts.spaceGrotesk(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.1,
    height: 1.3,
    color: color ?? onSurface.withValues(alpha: 0.55),
  );
}
