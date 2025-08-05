import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(-4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 50.0, left: 16.0, right: 16.0, bottom: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.nunito(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.check,
                                color: Theme.of(context).colorScheme.primary, size: 32),
                            onPressed: () {
                              provider.refresh();
                              Navigator.pop(context);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: Theme.of(context).colorScheme.error, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3), thickness: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildClearFiltersButton(context),
                        SizedBox(height: 20),
                        AIGeneratedFilter(),
                        SizedBox(height: 12),
                        OwnRecipesFilter(),
                        SizedBox(height: 20),
                        PrepTimeFilter(),
                        SizedBox(height: 20),
                        CookTimeFilter(),
                        SizedBox(height: 20),
                        CaloriesFilter(),
                        SizedBox(height: 20),
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
        TextButton(
          onPressed: provider.clearFilters,
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear, color: Theme.of(context).colorScheme.onErrorContainer, size: 20),
                SizedBox(width: 4),
                Text(
                  'Clear Filters',
                  style: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ),
      ],
    );
  }

}
