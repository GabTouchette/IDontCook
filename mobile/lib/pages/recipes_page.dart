import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

import 'package:i_cant_cook/pages/create_recipe_page.dart';
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            centerTitle: true,
            leading: IconButton(
              padding: const EdgeInsets.only(left: 16.0),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateRecipePage()),
                ).then((_) {
                  final recipesProvider =
                      Provider.of<UserRecipesProvider>(context, listen: false);
                  recipesProvider.fetchRecipes();
                });
              },
              icon: FaIcon(
                FontAwesomeIcons.plus,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Recipes',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [UserMenuWidget()],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120), // reduced height
              child: Column(
                children: [
                  _buildSearchBar(context),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFlexTab('All', 0, provider),
                        _buildFlexTab('Recent', 1, provider),
                        _buildFlexTab('Favorites', 2, provider),
                        _buildFlexTab('Tags', 3, provider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                children: [
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
                                  style: GoogleFonts.nunito(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
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
                                      onTap: () => provider.setSelectedTag(tag),
                                      splashColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withOpacity(0.2),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        child: Text(
                                          tag.toUpperCase(),
                                          style: GoogleFonts.nunito(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontWeight: FontWeight.w700,
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
                                style: GoogleFonts.nunito(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: provider.filteredRecipes.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // — the scrollable header row
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // “Showing X recipes” or tag‑back button
                                      provider.tabIndex == 3 &&
                                              provider.selectedTag != null
                                          ? GestureDetector(
                                              onTap: () =>
                                                  provider.setSelectedTag(null),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.chevron_left,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                      size: 24),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    provider.selectedTag!,
                                                    style: GoogleFonts.nunito(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Text(
                                              'Showing ${provider.filteredRecipes.length} recipes',
                                              style: GoogleFonts.nunito(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),

                                      // layout‑mode buttons
                                      Row(
                                        children: List.generate(3, (i) {
                                          const icons = [
                                            Icons.view_list,
                                            Icons.view_module,
                                            Icons.view_comfy
                                          ];
                                          const tooltips = [
                                            'Small view',
                                            'Medium view',
                                            'Large view'
                                          ];
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            decoration: BoxDecoration(
                                              color: provider.tileMode == i
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.1)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                width: 2,
                                                color: provider.tileMode == i
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.3)
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .outline
                                                        .withOpacity(0.2),
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: Icon(icons[i],
                                                  size: 20,
                                                  color: provider.tileMode == i
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant),
                                              onPressed: () =>
                                                  provider.setTileMode(i),
                                              tooltip: tooltips[i],
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // — your recipe items
                              final recipe =
                                  provider.filteredRecipes[index - 1];
                              return _buildRecipeTile(recipe);
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          style: GoogleFonts.nunito(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            hintText: 'Search for a recipe',
            hintStyle: GoogleFonts.nunito(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          ),
          onChanged: provider.onSearchTextChanged,
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

  Widget _buildFlexTab(
    String title,
    int index,
    UserRecipesProvider provider,
  ) {
    final isSelected = provider.tabIndex == index;

    return GestureDetector(
      onTap: () {
        provider.setTabIndex(index);
        if (index != 3) provider.setSelectedTag(null);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: isSelected
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              )
            : null,
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
