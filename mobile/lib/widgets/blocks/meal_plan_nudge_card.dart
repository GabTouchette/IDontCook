import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/home_module/home_module.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/theme/theme.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';

/// Renders a `meal_plan_nudge` module as a compact, warm-tinted banner
/// strip — week framing derived from `week_start`/`planned_days` ("0 of 7
/// days planned") and a prominent CTA button showing the payload's `cta`.
/// Tapping the CTA calls [onCtaTap] with the owning [module]
/// (`BlockCallbacks.onModuleCtaTap`).
class MealPlanNudgeCard extends StatelessWidget {
  final HomeModule module;
  final void Function(HomeModule module)? onCtaTap;

  const MealPlanNudgeCard({
    super.key,
    required this.module,
    this.onCtaTap,
  });

  MealPlanNudgePayload get payload =>
      module.payload as MealPlanNudgePayload;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.warning;
    final weekLabel = _weekLabel(payload.week_start);
    final plannedLabel = '${payload.planned_days} of 7 days planned';

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        border: Border(left: BorderSide(color: accent, width: 3.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_month_outlined, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekLabel.isNotEmpty ? weekLabel : 'This week',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plannedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                if (module.reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    module.reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: reasonTextStyle(context),
                  ),
                ],
              ],
            ),
          ),
          if (payload.cta.isNotEmpty) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => onCtaTap?.call(module),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 9.0, horizontal: 14.0),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  payload.cta,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats an `iso8601-date` `week_start` (e.g. `"2026-07-14"`) as
  /// "Week of Jul 14". Returns '' when [weekStart] is empty or unparseable.
  static String _weekLabel(String weekStart) {
    if (weekStart.isEmpty) return '';
    final date = DateTime.tryParse(weekStart);
    if (date == null) return '';
    return 'Week of ${_months[date.month - 1]} ${date.day}';
  }
}
