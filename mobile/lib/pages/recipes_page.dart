import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

import 'package:i_cant_cook/pages/create_recipe_page.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_tile.dart';
import 'package:i_cant_cook/providers/user_recipes_provider.dart';
import 'package:provider/provider.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  @override
  void initState() {
    super.initState();
    final recipesProvider =
        Provider.of<UserRecipesProvider>(context, listen: false);
    recipesProvider.fetchRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRecipesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
              padding: const EdgeInsets.only(left: 16.0),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateRecipePage(),
                  ),
                ).then((_) {
                  final recipesProvider =
                      Provider.of<UserRecipesProvider>(context, listen: false);
                  recipesProvider.fetchRecipes();
                });
              },
              icon: const FaIcon(
                FontAwesomeIcons.plus,
                color: ColorPalette.offWhite,
                size: 28,
              ),
            ),
            title: Text(
              'Recipes',
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
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/images/recipes_page_background.png',
                    fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Column(
                  children: [
                    _buildSearchBar(context),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTab('All', 0, provider),
                        _buildTab('Recent', 1, provider),
                        _buildTab('Favorites', 2, provider),
                        _buildTab('Tags', 3, provider),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        height: 1,
                        color: Colors.grey[400],
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (provider.tabIndex == 3 &&
                              provider.selectedTag == null) {
                            // Show tags grid only when on Tags tab and no tag selected
                            final tags = provider.userTags;
                            if (tags.isEmpty) {
                              return Center(
                                child: Text('No tags found.',
                                    style: TextStyle(
                                        color: ColorPalette.offWhite)),
                              );
                            }
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: GridView.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1,
                                padding: const EdgeInsets.only(top: 16.0),
                                children: tags.map((tag) {
                                  return GestureDetector(
                                    onTap: () => provider.setSelectedTag(tag),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () =>
                                            provider.setSelectedTag(tag),
                                        splashColor: Colors.white24,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                ColorPalette.darkgray,
                                                ColorPalette.darkergray
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Text(
                                            tag.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              letterSpacing: 1.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          } else {
                            // Show recipe list (filteredRecipes) for all other cases
                            if (provider.filteredRecipes.isEmpty) {
                              return Center(
                                child: Text(
                                  'No recipes were found.',
                                  style:
                                      TextStyle(color: ColorPalette.offWhite),
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: provider.filteredRecipes.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // Header row with count and tile mode buttons
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        provider.tabIndex == 3 &&
                                                provider.selectedTag != null
                                            ? GestureDetector(
                                                onTap: () {
                                                  provider.setSelectedTag(null);
                                                },
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.chevron_left,
                                                      color:
                                                          ColorPalette.offWhite,
                                                      size: 36,
                                                    ),
                                                    Text(
                                                      provider.selectedTag!,
                                                      style: const TextStyle(
                                                          color: ColorPalette
                                                              .offWhite,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Text(
                                                'Showing ${provider.filteredRecipes.length} recipes',
                                                style: const TextStyle(
                                                  color: ColorPalette.offWhite,
                                                  fontSize: 18,
                                                ),
                                              ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.view_list,
                                                  color: provider.tileMode == 0
                                                      ? Colors.white
                                                      : ColorPalette
                                                          .placeholdergray),
                                              onPressed: () =>
                                                  provider.setTileMode(0),
                                              tooltip: 'Small view',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.view_module,
                                                  color: provider.tileMode == 1
                                                      ? Colors.white
                                                      : ColorPalette
                                                          .placeholdergray),
                                              onPressed: () =>
                                                  provider.setTileMode(1),
                                              tooltip: 'Medium view',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.view_comfy,
                                                  color: provider.tileMode == 2
                                                      ? Colors.white
                                                      : ColorPalette
                                                          .placeholdergray),
                                              onPressed: () =>
                                                  provider.setTileMode(2),
                                              tooltip: 'Large view',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  final recipe =
                                      provider.filteredRecipes[index - 1];
                                  return _buildRecipeTile(recipe);
                                }
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final provider = Provider.of<UserRecipesProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: ColorPalette.darkergray,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: ColorPalette.darkgray),
        ),
        child: TextField(
          style: TextStyle(
            color: ColorPalette.offWhite,
          ),
          decoration: InputDecoration(
            icon: const Icon(
              Icons.search,
              color: ColorPalette.offWhite,
            ),
            hintText: 'Search for a recipe',
            hintStyle: TextStyle(
              color: ColorPalette.placeholdergray,
            ),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          ),
          onChanged: provider.onSearchChanged,
        ),
      ),
    );
  }

  Widget _buildRecipeTile(RecipePreview recipe) {
    final provider = Provider.of<UserRecipesProvider>(context, listen: false);
    final tileMode = provider.tileMode;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axis: Axis.vertical,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('tile-${recipe.id}-mode-$tileMode'),
        child: RecipeTile(
          recipe: recipe,
          small: tileMode == 0,
          medium: tileMode == 1,
          large: tileMode == 2,
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index, UserRecipesProvider provider) {
    bool isSelected = provider.tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          provider.setTabIndex(index);
          if (index != 3)
            provider.setSelectedTag(null); // Clear tag when leaving Tags tab
        },
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border(bottom: BorderSide(color: Colors.white, width: 1.0))
                : null,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? ColorPalette.offWhite
                        : ColorPalette.placeholdergray,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
