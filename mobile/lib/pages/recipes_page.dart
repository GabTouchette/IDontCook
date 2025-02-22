import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:mobile/pages/create_recipe_page.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/appbar/appbar_user_menu.dart';
import 'package:mobile/widgets/recipes/recipe_tile.dart';
import 'package:mobile/providers/recipes_provider.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecipesProvider()..fetchRecipes(),
      child: Consumer<RecipesProvider>(
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
                        Provider.of<RecipesProvider>(context, listen: false);
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
                  child: Image.asset(
                      'assets/images/recipes_page_background.png',
                      fit: BoxFit.cover),
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
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 8.0),
                            ),
                            onChanged: provider.onSearchChanged,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTab('All', 0, provider),
                          _buildTab('Recent', 1, provider),
                          _buildTab('Favorites', 2, provider),
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
                        child: Stack(
                          children: [
                            provider.filteredRecipes.isEmpty
                                ? Center(
                                    child: Text(
                                      'No recipes found.',
                                      style: TextStyle(
                                          color: ColorPalette.offWhite),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount:
                                        provider.filteredRecipes.length + 1,
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
        },
      ),
    );
  }

  Widget _buildTab(String title, int index, RecipesProvider provider) {
    bool isSelected = provider.tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTabIndex(index),
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
