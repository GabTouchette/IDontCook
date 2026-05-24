import 'package:flutter/material.dart';
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            elevation: 0,
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
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            title: Text(
              'RECIPES',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 2.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
            actions: [UserMenuWidget()],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(116),
              child: Column(
                children: [
                  _buildSearchBar(context),
                  _buildTabRow(context, provider),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (provider.tabIndex == 3 &&
                        provider.selectedTag == null) {
                      return _buildTagsGrid(context, provider);
                    }
                    if (provider.filteredRecipes.isEmpty) {
                      return Center(
                        child: Text(
                          'No recipes found.',
                          style: GoogleFonts.spaceGrotesk(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: provider.filteredRecipes.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return _buildListHeader(context, provider);
                        final recipe = provider.filteredRecipes[index - 1];
                        return _buildRecipeTile(recipe);
                      },
                    );
                  },
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: TextField(
          style: GoogleFonts.spaceGrotesk(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 20,
            ),
            hintText: 'Search recipes…',
            hintStyle: GoogleFonts.spaceGrotesk(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
              fontSize: 15,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          ),
          onChanged: provider.onSearchTextChanged,
        ),
      ),
    );
  }

  Widget _buildTabRow(BuildContext context, UserRecipesProvider provider) {
    const tabs = ['ALL', 'RECENT', 'FAVORITES', 'TAGS'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = provider.tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 3) {
                  if (provider.tabIndex == 3 && provider.selectedTag != null) {
                    provider.setSelectedTag(null);
                  } else {
                    provider.setTabIndex(3);
                  }
                } else {
                  provider.setTabIndex(i);
                  provider.setSelectedTag(null);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                child: isSelected
                    ? Container(
                        color: const Color(0xFFCAFF00),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: Text(
                          tabs[i],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                      )
                    : Text(
                        tabs[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.35),
                        ),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTagsGrid(BuildContext context, UserRecipesProvider provider) {
    final tags = provider.userTags;
    if (tags.isEmpty) {
      return Center(
        child: Text(
          'No tags found.',
          style: GoogleFonts.spaceGrotesk(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 15,
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      childAspectRatio: 1.4,
      padding: EdgeInsets.zero,
      children: tags.map((tag) {
        return GestureDetector(
          onTap: () => provider.setSelectedTag(tag),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.outline.withOpacity(0.12),
                width: 0.5,
              ),
            ),
            alignment: Alignment.center,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              tag.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListHeader(
      BuildContext context, UserRecipesProvider provider) {
    const icons = [Icons.view_list, Icons.view_module, Icons.view_comfy];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          if (provider.tabIndex == 3 && provider.selectedTag != null)
            GestureDetector(
              onTap: () => provider.setSelectedTag(null),
              child: Row(
                children: [
                  Icon(Icons.arrow_back,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(width: 6),
                  Text(
                    provider.selectedTag!.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              '${provider.filteredRecipes.length} RECIPES',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4),
              ),
            ),
          const Spacer(),
          // Layout toggles — flat squares
          Row(
            children: List.generate(3, (i) {
              final isActive = provider.tileMode == i;
              return GestureDetector(
                onTap: () => provider.setTileMode(i),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(left: 6),
                  color: isActive
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  child: Icon(
                    icons[i],
                    size: 20,
                    color: isActive
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeTile(RecipePreview recipe) {
    final provider = Provider.of<UserRecipesProvider>(context, listen: false);
    final tileMode = provider.tileMode;

    return RecipeTile(
      recipe: recipe,
      small: tileMode == 0,
      medium: tileMode == 1,
      large: tileMode == 2,
    );
  }
}
