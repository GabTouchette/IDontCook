import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';
import 'package:i_cant_cook/widgets/explore/recipe_search_filter_drawer.dart';
import 'package:i_cant_cook/widgets/recommendations/big_recipe_tile.dart';
import 'package:provider/provider.dart';

class ExplorePage extends StatelessWidget {
  ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: ColorPalette.darkergray,
            ),
          ),
          Column(
            children: [
              _buildSearchBar(context),
              Expanded(
                child: Consumer<ExploreProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.items.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: ColorPalette.offWhite,
                        ),
                      );
                    }

                    if (provider.items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No recipes found.',
                          style: TextStyle(color: ColorPalette.offWhite),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: provider.scrollController,
                      itemCount: provider.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Found ${provider.items.length} recipe${provider.items.length == 1 ? "" : "s"}',
                                  style: const TextStyle(
                                    color: ColorPalette.offWhite,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (index == provider.items.length) {
                          return provider.isFetching
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: ColorPalette.offWhite,
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 100);
                        }

                        final recipe = provider.items[index - 1];
                        return BigRecipeTile(recipe: recipe);
                      },
                    );
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ColorPalette.darkergray,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Explore Recipes',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: ColorPalette.offWhite,
        ),
      ),
      actions: const [UserMenuWidget()],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final provider = Provider.of<ExploreProvider>(context, listen: false);

    return Padding(
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
            const Icon(Icons.search, color: ColorPalette.offWhite),
            const SizedBox(width: 8.0),
            Expanded(
              child: TextField(
                controller: provider.searchController,
                style: const TextStyle(color: ColorPalette.offWhite),
                decoration: const InputDecoration(
                  hintText: 'Search recipes',
                  hintStyle: TextStyle(color: ColorPalette.placeholdergray),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                ),
                onChanged: (query) => provider.onSearchChanged(
                  query,
                  (_) => provider.fetchInitialItems(),
                ),
              ),
            ),
            IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.sliders,
                color: ColorPalette.offWhite,
                size: 24,
              ),
              onPressed: () => _openFilterDrawer(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Filters",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: RecipeSearchFilterDrawer(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset(0, 0))
              .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        );
      },
    );
  }
}
