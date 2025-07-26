import 'package:flutter/material.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:provider/provider.dart';

class CookTimeFilter extends StatelessWidget {
  const CookTimeFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        final value = (provider.filters['cookTime'] ?? 0).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cook Time',
                style: TextStyle(
                    color: ColorPalette.offWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Slider(
              value: value,
              min: 0,
              max: 60,
              divisions: 30,
              label: value == 60 ? 'Any' : '${value.round()} min',
              onChanged: (val) => provider.updateFilter('cookTime', val),
              activeColor: ColorPalette.gray,
              inactiveColor: ColorPalette.darkgray,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0 min', style: TextStyle(color: ColorPalette.offWhite)),
                  Text('Any',
                      style: TextStyle(
                          color: ColorPalette.offWhite,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
