import 'package:flutter/material.dart';
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
    if (!_hasFetched) {
      Provider.of<ExploreProvider>(context, listen: false).fetchInitialItems();
      _hasFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          'EXPLORE',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 2.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [UserMenuWidget()],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
        children: [
          _buildSearchBar(context),
          _buildFilterNotification(context),
          const SizedBox(height: 14),
          Expanded(
            child: Consumer<ExploreProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onSurface,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (provider.items.isEmpty) {
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
                  controller: provider.scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.zero,
                  itemCount: provider.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == provider.items.length) {
                      return provider.isFetching
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const SizedBox(height: 60);
                    }
                    return BigRecipeTile(recipe: provider.items[index]);
                  },
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final provider = Provider.of<ExploreProvider>(context, listen: false);

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
        child: Row(
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: provider.searchController,
              builder: (context, value, _) {
                final hasText = value.text.isNotEmpty;
                return GestureDetector(
                  onTap: hasText
                      ? () {
                          provider.searchController.clear();
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(
                      hasText ? Icons.close : Icons.search,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(hasText ? 0.7 : 0.4),
                      size: 20,
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: provider.searchController,
                style: GoogleFonts.spaceGrotesk(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Search recipes…',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.35),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 4.0),
                ),
                // Search is driven by searchController.addListener in the provider.
              ),
            ),
            GestureDetector(
              onTap: () => _openFilterDrawer(context),
              child: Consumer<ExploreProvider>(
                builder: (context, p, _) => Container(
                  width: 46,
                  height: 46,
                  color: p.hasActiveFilters
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  child: Icon(
                    Icons.tune,
                    size: 18,
                    color: p.hasActiveFilters
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterNotification(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        if (!provider.hasActiveFilters) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Icon(
                Icons.filter_alt_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'FILTERS ACTIVE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: provider.clearFilters,
                child: Text(
                  'CLEAR',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFilterDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filters',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: RecipeSearchFilterDrawer(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}

