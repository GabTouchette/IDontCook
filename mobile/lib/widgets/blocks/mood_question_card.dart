import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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
        // Single-line marquee: pills auto-scroll slowly in an infinite loop.
        // The user can grab and scroll manually (which pauses the auto-scroll)
        // and tap a pill; releasing resumes the loop from wherever it landed.
        _MoodPillsMarquee(
          options: options,
          selectedMood: selectedMood,
          onMoodSelected: onMoodSelected,
        ),
      ],
    );
  }
}

/// A single horizontal line of mood pills that auto-scrolls slowly and loops
/// forever. The content is laid out as a repeating run of the pill set; a
/// [Ticker] advances the scroll offset every frame and wraps it back by one
/// set width once it passes the seam, so the loop is seamless.
///
/// Pointer-down pauses the animation (so a manual drag or a tap is never
/// fought by the auto-scroll); pointer-up/cancel resumes it from wherever the
/// user left the offset. Because the scroll view itself handles the drag, the
/// user gets normal momentum/fling while interacting.
class _MoodPillsMarquee extends StatefulWidget {
  final List<MoodOption> options;
  final Mood? selectedMood;
  final void Function(Mood mood)? onMoodSelected;

  const _MoodPillsMarquee({
    required this.options,
    this.selectedMood,
    this.onMoodSelected,
  });

  @override
  State<_MoodPillsMarquee> createState() => _MoodPillsMarqueeState();
}

class _MoodPillsMarqueeState extends State<_MoodPillsMarquee>
    with SingleTickerProviderStateMixin {
  // Slow, gentle drift.
  static const double _pixelsPerSecond = 22.0;
  static const double _gap = 8.0;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _setKey = GlobalKey();

  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  double _setWidth = 0; // width of one full pill set, including trailing gap
  int _copies = 3; // enough repeats to cover the viewport + one seam
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _MoodPillsMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pill set may change width when options change; re-measure next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final setBox = _setKey.currentContext?.findRenderObject() as RenderBox?;
    final viewportWidth = context.size?.width ?? 0;
    if (setBox == null || !setBox.hasSize) return;
    final width = setBox.size.width;
    if (width <= 0) return;
    // Repeat enough that the visible window (viewport) plus the one-set wrap
    // margin is always filled with pills.
    final needed = ((viewportWidth / width).ceil()) + 2;
    final copies = needed < 3 ? 3 : needed;
    if (width != _setWidth || copies != _copies) {
      setState(() {
        _setWidth = width;
        _copies = copies;
      });
    }
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    if (_paused || _setWidth <= 0 || !_scroll.hasClients) return;
    final dt = delta.inMicroseconds / Duration.microsecondsPerSecond;
    var next = _scroll.offset + _pixelsPerSecond * dt;
    // Wrap by whole sets so the offset stays in a stable range and the seam
    // is invisible (each set is identical).
    while (next >= _setWidth) {
      next -= _setWidth;
    }
    _scroll.jumpTo(next);
  }

  void _pause() => _paused = true;

  void _resume() {
    if (!mounted) return;
    // Normalize whatever offset the drag/fling left us at back into the first
    // seam window so the ongoing loop stays seamless.
    if (_scroll.hasClients && _setWidth > 0) {
      var o = _scroll.offset % _setWidth;
      if (o < 0) o += _setWidth;
      _scroll.jumpTo(o);
    }
    _lastElapsed = _ticker?.isActive == true ? _lastElapsed : Duration.zero;
    _paused = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _pause(),
      onPointerUp: (_) => _resume(),
      onPointerCancel: (_) => _resume(),
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _copies; i++)
              _MoodPillSet(
                key: i == 0 ? _setKey : null,
                options: widget.options,
                selectedMood: widget.selectedMood,
                onMoodSelected: widget.onMoodSelected,
                gap: _gap,
              ),
          ],
        ),
      ),
    );
  }
}

/// One run of every pill, each separated by [gap] and with a trailing [gap]
/// so that consecutive sets keep uniform spacing across the seam.
class _MoodPillSet extends StatelessWidget {
  final List<MoodOption> options;
  final Mood? selectedMood;
  final void Function(Mood mood)? onMoodSelected;
  final double gap;

  const _MoodPillSet({
    super.key,
    required this.options,
    required this.selectedMood,
    required this.onMoodSelected,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          Padding(
            padding: EdgeInsets.only(right: gap),
            child: _MoodChoiceChip(
              option: option,
              selected:
                  selectedMood != null && selectedMood == option.moodValue,
              onTap: () => onMoodSelected?.call(option.moodValue!),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // Each mood carries its own accent so the row reads as a colorful palette.
    // Unknown moods (moodValue == null) fall back to the neutral on-surface
    // tone — but those options are filtered out upstream, so this is defensive.
    final accent =
        option.moodValue != null ? moodColor(option.moodValue!) : onSurface;
    // Selected: everything sits on the accent fill, so use readable ink.
    // Unselected: the icon carries the mood color while the label stays a
    // neutral on-surface tone (colored label text — e.g. amber on white —
    // reads poorly).
    final ink = selected ? onColorInk(accent) : onSurface;
    final iconColor = selected ? onColorInk(accent) : accent;

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
            : BoxDecoration(
                // Faint tint of the mood's own color, with a matching outline —
                // colorful but low-key until picked.
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: accent.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.moodValue != null) ...[
              Icon(moodIcon(option.moodValue!), size: 16, color: iconColor),
              const SizedBox(width: 6),
            ],
            Text(
              option.label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
