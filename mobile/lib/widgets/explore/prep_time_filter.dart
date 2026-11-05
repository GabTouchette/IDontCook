import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:provider/provider.dart';

class PrepTimeFilter extends StatelessWidget {
  const PrepTimeFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        final lime = Theme.of(context).colorScheme.secondary;
        final value = (provider.filters['prepTime'] ?? 60).toDouble();
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
                      'PREP TIME',
                      style: GoogleFonts.spaceGrotesk(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(width: 20, height: 2, color: lime),
                  ],
                ),
                Text(
                  value == 60 ? 'Any' : '${value.round()} min',
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
                activeTrackColor: lime,
                inactiveTrackColor:
                    Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                thumbColor: lime,
                overlayColor: lime.withValues(alpha: 0.15),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                valueIndicatorColor: Theme.of(context).colorScheme.onSurface,
                valueIndicatorTextStyle: GoogleFonts.spaceGrotesk(
                  color: lime,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                showValueIndicator: ShowValueIndicator.always,
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 60,
                divisions: 30,
                label: value == 60 ? 'Any' : '${value.round()} min',
                onChanged: (val) => provider.updateFilter('prepTime', val),
              ),
            ),
          ],
        );
      },
    );
  }
}
