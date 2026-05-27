import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/widgets/explore/ai_generated_filter.dart';
import 'package:i_cant_cook/widgets/explore/calories_filter.dart';
import 'package:i_cant_cook/widgets/explore/own_recipes_filter.dart';
import 'package:i_cant_cook/widgets/explore/tag_filter.dart';
import 'package:i_cant_cook/widgets/explore/total_time_filter.dart';
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
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 56.0, left: 16.0, right: 16.0, bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FILTERS',
                        style: GoogleFonts.spaceGrotesk(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              provider.refresh();
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              color: Theme.of(context).colorScheme.onSurface,
                              child: Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.surface,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.12),
                    thickness: 1,
                    height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Column(
                      children: [
                        _buildClearFiltersButton(context),
                        const SizedBox(height: 14),
                        _buildSectionDivider(context),
                        const SizedBox(height: 10),
                        AIGeneratedFilter(),
                        _buildSectionDivider(context),
                        OwnRecipesFilter(),
                        _buildSectionDivider(context),
                        TotalTimeFilter(),
                        _buildSectionDivider(context),
                        CaloriesFilter(),
                        _buildSectionDivider(context),
                        const SizedBox(height: 4),
                        TagFilters(),
                        const SizedBox(height: 20),
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

  Widget _buildSectionDivider(BuildContext context) {
    return Divider(
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
      thickness: 1,
      height: 1,
    );
  }

  Widget _buildClearFiltersButton(BuildContext context) {
    final provider = Provider.of<ExploreProvider>(context, listen: false);

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: provider.clearFilters,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.clear,
                  color: Theme.of(context).colorScheme.onSurface, size: 16),
              const SizedBox(width: 6),
              Text(
                'CLEAR FILTERS',
                style: GoogleFonts.spaceGrotesk(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
