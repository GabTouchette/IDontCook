import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/services/haptic_service.dart';

class WeeklyCalendar extends StatefulWidget {
  final DateTime weekStart;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final Set<int> selectedDays; // Changed from range to Set
  final VoidCallback? onSwipeLeft; // next week
  final VoidCallback? onSwipeRight; // previous week
  final double? height; // optional override for total height
  final int weekOffset; // Current week offset for carousel

  const WeeklyCalendar({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.onDaySelected,
    required this.selectedDays, // Now required Set instead of optional range
    this.onSwipeLeft,
    this.onSwipeRight,
    this.height,
    required this.weekOffset,
  });

  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> 
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.weekOffset + 10000);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
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
              child: Row(
                children: [
                  // Previous week button
                  IconButton(
                    onPressed: () {
                      HapticService.lightImpact();
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(
                      Icons.chevron_left,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      monthLabel,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Next week button
                  IconButton(
                    onPressed: () {
                      HapticService.lightImpact();
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  final actualPage = page - 10000;
                  if (actualPage > widget.weekOffset) {
                    widget.onSwipeLeft?.call(); // Next week
                  } else if (actualPage < widget.weekOffset) {
                    widget.onSwipeRight?.call(); // Previous week
                  }
                },
                itemBuilder: (context, index) {
                  // Calculate the week for this page
                  final weekOffset = index - 10000;
                  final baseWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
                  final currentWeekStart = baseWeek.add(Duration(days: 7 * weekOffset));
                  final weekDays = List.generate(7, (i) => currentWeekStart.add(Duration(days: i)));
                  
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          children: [
                            for (int i = 0; i < 7; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _DayTile(
                                  day: weekDays[i],
                                  dayIndex: i,
                                  weekdayLabel: _weekdayLabel(weekDays[i].weekday),
                                  selected: weekOffset == widget.weekOffset && widget.selectedDays.contains(i),
                                  isToday: _isSameDay(weekDays[i], today),
                                  onTap: () => widget.onDaySelected(i),
                                ),
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
  final int dayIndex;
  final String weekdayLabel;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayTile({
    required this.day,
    required this.dayIndex,
    required this.weekdayLabel,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface; // Always use surface background
    final fg = theme.colorScheme.onSurface; // Always use onSurface text
    final sub = theme.colorScheme.onSurfaceVariant; // Always use variant text

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : isToday && !selected
                  ? Colors.transparent // Hide solid border when today is unselected
                  : theme.colorScheme.outline.withOpacity(0.2),
          width: selected ? 2.5 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ]
            : null,
      ),
      child: SizedBox(
        height: 60, // Fixed height for all days
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Always allocate space for "Today" label to keep consistent height
            SizedBox(
              height: isToday ? null : 9, // Match Today text height when not shown
              child: isToday
                  ? Text(
                      'Today',
                      style: GoogleFonts.nunito(
                        color: theme.colorScheme.primary,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 1),
            Text(
              weekdayLabel,
              style: GoogleFonts.nunito(
                color: fg, 
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                '${day.day}',
                key: ValueKey<int>(day.day),
                style: GoogleFonts.nunito(
                    color: sub,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2),
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with a dotted border for today when unselected
    if (isToday && !selected) {
      container = CustomPaint(
        painter: _DottedBorderPainter(
          color: theme.colorScheme.primary.withOpacity(0.8),
          strokeWidth: 2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: container,
      );
    }

    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: container,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  static const double dashLength = 4;
  static const double gapLength = 3;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required BorderRadius borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth,
          size.height - strokeWidth),
      const Radius.circular(14),
    );

    final path = Path()..addRRect(rrect);

    _drawDottedPath(canvas, path, paint);
  }

  void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
