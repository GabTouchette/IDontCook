import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:provider/provider.dart';

class AIGeneratedFilter extends StatelessWidget {
  const AIGeneratedFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'EXCLUDE AI-GENERATED',
                style: GoogleFonts.spaceGrotesk(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            Switch(
              value: provider.filters['excludeAIGenerated'] ?? false,
              onChanged: (value) =>
                  provider.updateFilter('excludeAIGenerated', value),
              activeColor: Theme.of(context).colorScheme.onSecondary,
              activeTrackColor: Theme.of(context).colorScheme.secondary,
              inactiveThumbColor: Theme.of(context).colorScheme.outline,
              inactiveTrackColor:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
          ),
        );
      },
    );
  }
}
