import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:provider/provider.dart';

class OwnRecipesFilter extends StatelessWidget {
  const OwnRecipesFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Exclude My Recipes',
                  style: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: provider.filters['excludeOwnRecipes'] ?? true,
                onChanged: (value) =>
                    provider.updateFilter('excludeOwnRecipes', value),
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveThumbColor: Theme.of(context).colorScheme.outline,
                inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        );
      },
    );
  }
}
