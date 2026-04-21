import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';
import 'package:i_cant_cook/widgets/explore/recipe_search_filter_drawer.dart';
import 'package:i_cant_cook/widgets/recommendations/big_recipe_tile.dart';
import 'package:provider/provider.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ensure it's only called once
    if (!_hasFetched) {
      Provider.of<ExploreProvider>(context, listen: false).fetchInitialItems();
      _hasFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Explore Recipes',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [UserMenuWidget()],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          Column(
            children: [
              _buildSearchBar(context),
              _buildFilterNotification(context),
              Expanded(
                child: Consumer<ExploreProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.items.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }

                    if (provider.items.isEmpty) {
                      return Center(
                        child: Text(
                          'No recipes found.',
                          style: GoogleFonts.nunito(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: provider.scrollController,
                      itemCount: provider.items.length,
                      itemBuilder: (context, index) {
                        if (index == provider.items.length) {
                          return provider.isFetching
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 100);
                        }

                        final recipe = provider.items[index];
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

  Widget _buildSearchBar(BuildContext context) {
    final provider = Provider.of<ExploreProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: TextField(
                controller: provider.searchController,
                style: GoogleFonts.nunito(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search recipes',
                  hintStyle: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                ),
                onChanged: (query) => provider.onSearchChanged(
                  query,
                  (_) => provider.fetchInitialItems(),
                ),
              ),
            ),
            IconButton(
              icon: FaIcon(
                FontAwesomeIcons.sliders,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              onPressed: () => _openFilterDrawer(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterNotification(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        if (!provider.hasActiveFilters) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final onContainer = theme.colorScheme.onSecondaryContainer;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          constraints: const BoxConstraints(minHeight: 44),
          child: Material(
            color: theme.colorScheme.secondaryContainer,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => _openFilterDrawer(context),
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0, left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_rounded,
                      color: onContainer,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filters applied',
                      style: GoogleFonts.nunito(
                        color: onContainer,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 24),
                    TextButton.icon(
                      onPressed: provider.clearFilters,
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: onContainer),
                      label: Text(
                        'Clear',
                        style: GoogleFonts.nunito(
                          color: onContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(88, 40),
                        shape: const StadiumBorder(),
                        foregroundColor: onContainer,
                        backgroundColor: onContainer.withOpacity(0.08),
                        overlayColor: onContainer.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
