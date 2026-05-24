import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:provider/provider.dart';

class CaloriesFilter extends StatelessWidget {
  const CaloriesFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        final RangeValues values = provider.filters['calories'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CALORIES',
                      style: GoogleFonts.spaceGrotesk(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(width: 20, height: 2, color: const Color(0xFFCAFF00)),
                  ],
                ),
                Text(
                  '${values.start.round()} – ${values.end == 1000 ? 'Any' : '${values.end.round()} cal'}',
                  style: GoogleFonts.spaceGrotesk(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFCAFF00),
                inactiveTrackColor:
                    Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                thumbColor: const Color(0xFFCAFF00),
                overlayColor: const Color(0xFFCAFF00).withValues(alpha: 0.15),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 7),
                valueIndicatorColor: const Color(0xFF0A0A0A),
                valueIndicatorTextStyle: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFFCAFF00),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                showValueIndicator: ShowValueIndicator.always,
              ),
              child: RangeSlider(
                values: values,
                min: 0,
                max: 1000,
                divisions: 20,
                labels: RangeLabels(
                  '${values.start.round()} cal',
                  values.end == 1000 ? 'Any' : '${values.end.round()} cal',
                ),
                onChanged: (val) => provider.updateFilter('calories', val),
              ),
            ),
          ],
        );
      },
    );
  }
}
