import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';

/// Renders a `mood_question` module: the question read as an inline line
/// (no bordered box around it), followed by a horizontal row of rounded
/// icon+label pills. Selecting one calls [onMoodSelected] — Wave 2 wires
/// this to re-fetching the feed with `?mood=` (plan §1.5).
///
/// Options whose mood string is unknown to this app version are skipped
/// (forward-compat rule).
///
/// When [selectedMood] is set, the tapped pill is shown filled/highlighted
/// immediately (tap feedback that doesn't wait on the feed refetch) — the
/// caller (`home_page.dart`) sets this synchronously on tap, before the
/// network round trip completes, so the selection never reads as "nothing
/// happened".
class MoodQuestionCard extends StatelessWidget {
  final MoodQuestionPayload payload;
  final void Function(Mood mood)? onMoodSelected;
  final Mood? selectedMood;

  const MoodQuestionCard({
    super.key,
    required this.payload,
    this.onMoodSelected,
    this.selectedMood,
  });

  @override
  Widget build(BuildContext context) {
    final options =
        payload.options.where((option) => option.moodValue != null).toList();
    if (payload.question.isEmpty && options.isEmpty) {
      return const SizedBox.shrink();
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payload.question.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(2.0, 0, 2.0, 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.psychology_outlined, size: 18, color: onSurface),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    payload.question,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in options) ...[
                _MoodChoiceChip(
                  option: option,
                  selected: selectedMood != null &&
                      selectedMood == option.moodValue,
                  onTap: () => onMoodSelected?.call(option.moodValue!),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MoodChoiceChip extends StatelessWidget {
  final MoodOption option;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChoiceChip({
    required this.option,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fg = selected ? Theme.of(context).colorScheme.onPrimary : onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 14.0),
        decoration: selected
            ? BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent, width: 1.5),
              )
            : blockPillDecoration(
                context,
                outlineOpacity: 0.2,
                fill: onSurface.withValues(alpha: 0.04),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.moodValue != null) ...[
              Icon(moodIcon(option.moodValue!), size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              option.label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
