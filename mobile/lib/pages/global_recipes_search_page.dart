import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i_cant_cook/providers/global_recipe_search_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/utils/constants.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_tile.dart';
import 'package:provider/provider.dart';

class GlobalRecipeSearchPage extends StatefulWidget {
  const GlobalRecipeSearchPage({super.key});

  @override
  _GlobalRecipeSearchPageState createState() => _GlobalRecipeSearchPageState();
}

class _GlobalRecipeSearchPageState extends State<GlobalRecipeSearchPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeSearchProvider>(builder: (context, provider, child) {
      return Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'Global Search',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: ColorPalette.offWhite,
            ),
          ),
          actions: [
            UserMenuWidget(),
          ],
        ),
        endDrawer: _buildFilterDrawer(),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/recipes_page_background.png',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: ColorPalette.darkergray,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: ColorPalette.darkgray),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: ColorPalette.offWhite,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: TextField(
                              style: TextStyle(
                                color: ColorPalette.offWhite,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Global recipe search',
                                hintStyle: TextStyle(
                                  color: ColorPalette.placeholdergray,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16.0, horizontal: 8.0),
                              ),
                              onChanged: provider.onSearchChanged,
                            ),
                          ),
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.sliders,
                              color: ColorPalette.offWhite,
                              size: 24,
                            ),
                            onPressed: _openFilterDrawer,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        provider.filteredRecipes.isEmpty
                            ? Center(
                                child: Text(
                                  'Your recipe list is empty, try adding a recipe!',
                                  style:
                                      TextStyle(color: ColorPalette.offWhite),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: provider.filteredRecipes.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      child: Text(
                                        'Showing ${provider.filteredRecipes.length} recipes',
                                        style: TextStyle(
                                          color: ColorPalette.offWhite,
                                          fontSize: 18,
                                        ),
                                      ),
                                    );
                                  } else {
                                    final recipe =
                                        provider.filteredRecipes[index - 1];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RecipeTile(
                                          recipe: recipe,
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _openFilterDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Filters",
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: _buildFilterDrawer(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
              .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  Widget _buildFilterDrawer() {
    return Consumer<RecipeSearchProvider>(builder: (context, provider, child) {
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
                      Text(
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
                            icon: Icon(Icons.check,
                                color: Colors.green, size: 32),
                            onPressed: () {
                              provider.applyFilters();
                              Navigator.pop(context);
                            },
                          ),
                          IconButton(
                            icon:
                                Icon(Icons.close, color: Colors.red, size: 32),
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
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: ColorPalette.lightgray),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  provider.clearFilters();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  minimumSize: Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.clear,
                                      color: ColorPalette.offWhite,
                                      size: 20,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Clear Filters',
                                      style: TextStyle(
                                        color: ColorPalette.offWhite,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildAIGeneratedFilter(),
                        const SizedBox(height: 15),
                        _buildOwnRecipesFilter(),
                        const SizedBox(height: 30),
                        _buildPrepTimeFilter(),
                        const SizedBox(height: 40),
                        _buildCookTimeFilter(),
                        const SizedBox(height: 40),
                        _buildCaloriesFilter(),
                        const SizedBox(height: 40),
                        _buildTagFilters(),
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

  Widget _buildAIGeneratedFilter() {
    return Consumer<RecipeSearchProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Text(
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
              onChanged: (value) {
                provider.updateFilter('excludeAIGenerated', value);
              },
              inactiveThumbColor: ColorPalette.lightgray,
              inactiveTrackColor: ColorPalette.darkgray,
              activeColor: ColorPalette.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOwnRecipesFilter() {
    return Consumer<RecipeSearchProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Text(
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
              onChanged: (value) {
                provider.updateFilter('excludeOwnRecipes', value);
              },
              inactiveThumbColor: ColorPalette.lightgray,
              inactiveTrackColor: ColorPalette.darkgray,
              activeColor: ColorPalette.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrepTimeFilter() {
    return Consumer<RecipeSearchProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prep Time (minutes)',
              style: TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: (provider.filters['prepTime'] ?? 0).toDouble(),
              min: 0,
              max: 60,
              divisions: 24,
              label: provider.filters['prepTime'] == 60
                  ? '∞'
                  : '${provider.filters['prepTime'].round()} min',
              onChanged: (value) {
                provider.updateFilter('prepTime', value);
              },
              activeColor: ColorPalette.gray,
              inactiveColor: ColorPalette.darkgray,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0 min',
                    style: TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '∞',
                    style: TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCookTimeFilter() {
    return Consumer<RecipeSearchProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cook Time (minutes)',
              style: TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: (provider.filters['cookTime'] ?? 0).toDouble(),
              min: 0,
              max: 120,
              divisions: 24,
              label: provider.filters['cookTime'] == 120
                  ? '∞'
                  : '${provider.filters['cookTime'].round()} min',
              onChanged: (value) {
                provider.updateFilter('cookTime', value);
              },
              activeColor: ColorPalette.gray,
              inactiveColor: ColorPalette.darkgray,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0 min',
                    style: TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '∞',
                    style: TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTagFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tagOptions.entries.map((entry) {
        return _buildCategoryFilter(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildCategoryFilter(String category, List<String> tags) {
    return Consumer<RecipeSearchProvider>(
      builder: (context, provider, child) {
        final selectedTags = provider.filters['selectedTags'] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: tags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    final updatedSelectedTags = List<String>.from(selectedTags);
                    if (selected) {
                      updatedSelectedTags.add(tag);
                    } else {
                      updatedSelectedTags.remove(tag);
                    }
                    provider.updateFilter('selectedTags', updatedSelectedTags);
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

  Widget _buildCaloriesFilter() {
    return Consumer<RecipeSearchProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calories',
              style: TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: ColorPalette.gray,
                inactiveTrackColor: ColorPalette.darkgray,
                thumbColor: ColorPalette.gray,
                overlayColor: ColorPalette.gray.withOpacity(0.2),
                valueIndicatorColor: ColorPalette.gray,
              ),
              child: RangeSlider(
                values: provider.filters['calories'],
                min: 0,
                max: 1000,
                divisions: 20,
                labels: RangeLabels(
                  '${provider.filters['calories'].start.round()} cal',
                  provider.filters['calories'].end == 1000
                      ? '∞'
                      : '${provider.filters['calories'].end.round()} cal',
                ),
                onChanged: (values) {
                  final updatedValue = RangeValues(
                    values.start,
                    values.end,
                  );
                  provider.updateFilter('calories', updatedValue);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0 cal',
                    style: TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '∞',
                    style: TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
