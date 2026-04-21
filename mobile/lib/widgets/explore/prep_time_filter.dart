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
        final value = (provider.filters['prepTime'] ?? 60).toDouble();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prep Time',
                  style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  thumbColor: Theme.of(context).colorScheme.primary,
                  overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  valueIndicatorColor: Theme.of(context).colorScheme.primary,
                  valueIndicatorTextStyle: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0 min', style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
                    Text('Any',
                        style: GoogleFonts.nunito(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
