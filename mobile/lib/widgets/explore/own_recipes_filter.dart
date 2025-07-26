import 'package:flutter/material.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:provider/provider.dart';

class OwnRecipesFilter extends StatelessWidget {
  const OwnRecipesFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            const Text(
              'Exclude My Recipes',
              style: TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Switch(
              value: provider.filters['excludeOwnRecipes'] ?? true,
              onChanged: (value) =>
                  provider.updateFilter('excludeOwnRecipes', value),
              inactiveThumbColor: ColorPalette.lightgray,
              inactiveTrackColor: ColorPalette.darkgray,
              activeColor: ColorPalette.green,
            ),
          ],
        );
      },
    );
  }
}
