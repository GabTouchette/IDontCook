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
        return Row(
          children: [
            Expanded(
              child: Text(
                'EXCLUDE AI-GENERATED',
                style: GoogleFonts.spaceGrotesk(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Switch(
              value: provider.filters['excludeAIGenerated'] ?? false,
              onChanged: (value) =>
                  provider.updateFilter('excludeAIGenerated', value),
              activeColor: const Color(0xFF0A0A0A),
              activeTrackColor: const Color(0xFFCAFF00),
              inactiveThumbColor: Theme.of(context).colorScheme.outline,
              inactiveTrackColor:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        );
      },
    );
  }
}
