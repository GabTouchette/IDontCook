import 'package:flutter/material.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';

import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/utils/constants.dart';
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
                      children: const [
                        _ClearFiltersButton(),
                        SizedBox(height: 20),
                        _AIGeneratedFilter(),
                        SizedBox(height: 15),
                        _OwnRecipesFilter(),
                        SizedBox(height: 30),
                        _PrepTimeFilter(),
                        SizedBox(height: 40),
                        _CookTimeFilter(),
                        SizedBox(height: 40),
                        _CaloriesFilter(),
                        SizedBox(height: 40),
                        _TagFilters(),
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
}

class _ClearFiltersButton extends StatelessWidget {
  const _ClearFiltersButton();

  @override
  Widget build(BuildContext context) {
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

class _AIGeneratedFilter extends StatelessWidget {
  const _AIGeneratedFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            const Text(
              'Exclude AI-Generated Recipes',
              style: TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Switch(
              value: provider.filters['excludeAIGenerated'] ?? false,
              onChanged: (value) =>
                  provider.updateFilter('excludeAIGenerated', value),
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

class _OwnRecipesFilter extends StatelessWidget {
  const _OwnRecipesFilter();

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

class _PrepTimeFilter extends StatelessWidget {
  const _PrepTimeFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        final value = (provider.filters['prepTime'] ?? 0).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prep Time (minutes)',
                style: TextStyle(
                    color: ColorPalette.offWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Slider(
              value: value,
              min: 0,
              max: 60,
              divisions: 24,
              label: value == 60 ? '∞' : '${value.round()} min',
              onChanged: (val) => provider.updateFilter('prepTime', val),
              activeColor: ColorPalette.gray,
              inactiveColor: ColorPalette.darkgray,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0 min', style: TextStyle(color: ColorPalette.offWhite)),
                  Text('∞',
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

class _CookTimeFilter extends StatelessWidget {
  const _CookTimeFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        final value = (provider.filters['cookTime'] ?? 0).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cook Time (minutes)',
                style: TextStyle(
                    color: ColorPalette.offWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Slider(
              value: value,
              min: 0,
              max: 120,
              divisions: 24,
              label: value == 120 ? '∞' : '${value.round()} min',
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
                  Text('∞',
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

class _CaloriesFilter extends StatelessWidget {
  const _CaloriesFilter();

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
                  values.end == 1000 ? '∞' : '${values.end.round()} cal',
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
                  Text('∞',
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

class _TagFilters extends StatelessWidget {
  const _TagFilters();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tagOptions.entries
          .map((entry) =>
              _CategoryFilter(category: entry.key, tags: entry.value))
          .toList(),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String category;
  final List<String> tags;

  const _CategoryFilter({required this.category, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        final selectedTags = provider.filters['selectedTags'] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(
                  color: ColorPalette.offWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: tags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    final updatedTags = List<String>.from(selectedTags);
                    selected ? updatedTags.add(tag) : updatedTags.remove(tag);
                    provider.updateFilter('selectedTags', updatedTags);
                  },
                  selectedColor: ColorPalette.lightgray,
                  backgroundColor: ColorPalette.darkgray,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? ColorPalette.darkgray
                        : ColorPalette.placeholdergray,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
