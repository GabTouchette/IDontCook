import 'package:flutter/material.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
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
            const Text('Calories',
                style: TextStyle(
                    color: ColorPalette.offWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: ColorPalette.gray,
                inactiveTrackColor: ColorPalette.darkgray,
                thumbColor: ColorPalette.gray,
                overlayColor: ColorPalette.gray.withOpacity(0.2),
                valueIndicatorColor: ColorPalette.gray,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0 cal', style: TextStyle(color: ColorPalette.offWhite)),
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
