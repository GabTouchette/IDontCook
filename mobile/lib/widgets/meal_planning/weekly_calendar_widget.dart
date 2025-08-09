import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklyCalendar extends StatefulWidget {
  final DateTime weekStart;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  // Optional range to highlight inclusively; if provided, draw a group border.
  final int? rangeStart;
  final int? rangeEnd;
  final VoidCallback? onSwipeLeft; // next week
  final VoidCallback? onSwipeRight; // previous week
  final double? height; // optional override for total height

  const WeeklyCalendar({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.onDaySelected,
    this.rangeStart,
    this.rangeEnd,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.height,
  });

  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  @override
  Widget build(BuildContext context) {
    final days =
        List.generate(7, (i) => widget.weekStart.add(Duration(days: i)));
    final theme = Theme.of(context);
    final start = widget.rangeStart;
    final end = widget.rangeEnd;
    final hasRange = start != null && end != null;
    final s = start ?? -1;
    final e = end ?? -2; // ensure e < s when no range

    final monthLabel = _monthYear(widget.weekStart);

    final double h = widget.height ?? 140;
    return SizedBox(
      height: h,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                monthLabel,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  final vx = details.velocity.pixelsPerSecond.dx;
                  if (vx < -200) {
                    widget.onSwipeLeft?.call();
                  } else if (vx > 200) {
                    widget.onSwipeRight?.call();
                  }
                },
                child: Stack(
                  children: [
                    if (hasRange)
                      LayoutBuilder(builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        const gap = 8.0;
                        final tileWidth = (totalWidth - gap * 6) / 7;
                        final left = start * (tileWidth + gap);
                        final width =
                            (end - start + 1) * tileWidth + (end - start) * gap;
                        return Positioned(
                          left: left,
                          top: 1,
                          bottom: 1,
                          width: width,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: theme.colorScheme.primary, width: 1.5),
                            ),
                          ),
                        );
                      }),
                    Row(
                      children: [
                        for (int i = 0; i < 7; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _DayTile(
                              day: days[i],
                              weekdayLabel: _weekdayLabel(days[i].weekday),
                              selected: i == widget.selectedDay,
                              inRange: hasRange && i >= s && i <= e,
                              rangeActive: hasRange,
                              onTap: () => widget.onDaySelected(i),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
      default:
        return '';
    }
  }

  String _monthYear(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _DayTile extends StatelessWidget {
  final DateTime day;
  final String weekdayLabel;
  final bool selected;
  final bool inRange;
  final bool rangeActive;
  final VoidCallback onTap;

  const _DayTile(
      {required this.day,
      required this.weekdayLabel,
      required this.selected,
      required this.inRange,
      required this.rangeActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // When multiple days are selected (a range), make all in-range tiles the same dark color.
    final bool fillSelected = rangeActive ? inRange : selected;
    final bg =
        fillSelected ? theme.colorScheme.primary : theme.colorScheme.surface;
    final fg = fillSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final sub = fillSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
  final bool showShadow = rangeActive ? inRange : selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      boxShadow: showShadow
              ? [
                  BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekdayLabel,
              style: GoogleFonts.nunito(color: fg, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                '${day.day}',
                key: ValueKey<int>(day.day),
                style: GoogleFonts.nunito(
                    color: sub,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
