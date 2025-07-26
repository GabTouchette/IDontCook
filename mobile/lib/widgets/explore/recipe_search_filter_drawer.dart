import 'package:flutter/material.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';

import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/explore/ai_generated_filter.dart';
import 'package:i_cant_cook/widgets/explore/calories_filter.dart';
import 'package:i_cant_cook/widgets/explore/cook_time_filter.dart';
import 'package:i_cant_cook/widgets/explore/own_recipes_filter.dart';
import 'package:i_cant_cook/widgets/explore/prep_time_filter.dart';
import 'package:i_cant_cook/widgets/explore/tag_filter.dart';
import 'package:provider/provider.dart';

class RecipeSearchFilterDrawer extends StatelessWidget {
  const RecipeSearchFilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(builder: (context, provider, child) {
      return Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: ColorPalette.darkergray,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 50.0, left: 16.0, right: 16.0, bottom: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          color: ColorPalette.offWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check,
                                color: Colors.green, size: 32),
                            onPressed: () {
                              provider.refresh();
                              Navigator.pop(context);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.red, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: ColorPalette.lightgray, thickness: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildClearFiltersButton(context),
                        SizedBox(height: 20),
                        AIGeneratedFilter(),
                        SizedBox(height: 15),
                        OwnRecipesFilter(),
                        SizedBox(height: 30),
                        PrepTimeFilter(),
                        SizedBox(height: 40),
                        CookTimeFilter(),
                        SizedBox(height: 40),
                        CaloriesFilter(),
                        SizedBox(height: 40),
                        TagFilters(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  _buildClearFiltersButton(BuildContext context) {
    final provider = Provider.of<ExploreProvider>(context, listen: false);

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorPalette.lightgray),
          ),
          child: TextButton(
            onPressed: provider.clearFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear, color: ColorPalette.offWhite, size: 20),
                SizedBox(width: 4),
                Text(
                  'Clear Filters',
                  style: TextStyle(color: ColorPalette.offWhite, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
