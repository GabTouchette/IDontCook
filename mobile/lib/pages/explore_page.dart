import 'package:flutter/material.dart';
import 'package:i_cant_cook/mixins/chat_context_mixin.dart';
import 'package:i_cant_cook/models/chat/chat_page_context.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/appbar/search_app_bar_scaffold.dart';
import 'package:i_cant_cook/widgets/explore/recipe_search_filter_drawer.dart';
import 'package:i_cant_cook/widgets/explore/reel_recipe_card.dart';
import 'package:i_cant_cook/widgets/skeletons/skeletons.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:provider/provider.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with ChatContextRegistrar {
  bool _hasFetched = false;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<ExploreProvider>(context, listen: false).fetchInitialItems();
        }
      });
    }
  }

  @override
  void dispose() {
    // Reset the search when leaving so a stale query doesn't linger on the next
    // visit. The provider outlives this page, so it must be cleared explicitly.
    Provider.of<ExploreProvider>(context, listen: false).resetSearch();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, ExploreProvider provider) {
    HapticService.selectionClick();
    _currentIndex = index;
    if (index >= provider.items.length - 3) {
      provider.fetchNextPage();
    }
  }

  /// Snapshot of the reel for the global chat: the recipe currently in view,
  /// the ones just below it, and any active search/filters.
  ChatPageContext _buildChatContext(ExploreProvider provider) {
    final items = provider.items;
    final idx =
        (items.isEmpty) ? 0 : _currentIndex.clamp(0, items.length - 1);
    final current = items.isNotEmpty ? items[idx] : null;
    final upcoming = items
        .skip(idx)
        .take(6)
        .map((r) => {'id': r.id, 'title': r.title})
        .toList();
    final selectedTags =
        (provider.filters['selectedTags'] as List?)?.cast<String>() ??
            const <String>[];
    final search = provider.searchQuery;

    final summaryParts = <String>[];
    if (current != null) summaryParts.add('Viewing "${current.title}"');
    if (search.isNotEmpty) summaryParts.add('search: "$search"');
    if (selectedTags.isNotEmpty) {
      summaryParts.add('filters: ${selectedTags.join(', ')}');
    }

    return ChatPageContext(
      label: 'Explore',
      pageKey: 'explore',
      summary: summaryParts.isEmpty ? null : summaryParts.join(' · '),
      data: {
        'surface': 'explore_reel',
        if (current != null)
          'current_recipe': {'id': current.id, 'title': current.title},
        if (search.isNotEmpty) 'search': search,
        if (selectedTags.isNotEmpty) 'selected_tags': selectedTags,
        'visible_recipes': upcoming,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SearchAppBarScaffold(
      title: 'EXPLORE',
      expandedBuilder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchBar(context),
          _buildFilterNotification(context),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Consumer<ExploreProvider>(
          builder: (context, provider, _) {
            registerChatContext(_buildChatContext(provider));
            if (provider.isLoading && provider.items.isEmpty) {
              return const ExploreReelSkeleton();
            }

            if (provider.items.isEmpty) {
              return _buildExploreEmptyState(context, provider);
            }

            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: provider.items.length,
                  onPageChanged: (index) => _onPageChanged(index, provider),
                  itemBuilder: (context, index) {
                    final recipe = provider.items[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ReelRecipeCard(
                          key: ValueKey(recipe.id),
                          recipe: recipe,
                          onFavorited: () => provider.recordUpvote(recipe.id),
                          onThumbsDown: () =>
                              provider.recordDownvote(recipe.id),
                          onOpen: () => provider.recordClick(recipe.id),
                          onDelete: () async {
                            final success =
                                await provider.adminDeleteRecipe(recipe.id);
                            if (!success && context.mounted) {
                              InformationToast.error(
                                context,
                                'Delete failed — make sure your account has staff permissions.',
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                if (provider.isFetching)
                  Positioned(
                    top: 24,
                    right: 32,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            );
          },
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
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
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
                          HapticService.lightImpact();
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
                          .withValues(alpha: hasText ? 0.7 : 0.4),
                      size: 20,
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: provider.searchController,
                autofocus: true,
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
                        .withValues(alpha: 0.35),
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
              onTap: () {
                HapticService.selectionClick();
                _openFilterDrawer(context);
              },
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
                            .withValues(alpha: 0.45),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'FILTERS ACTIVE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticService.lightImpact();
                  provider.clearFilters();
                },
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

  Widget _buildExploreEmptyState(BuildContext context, ExploreProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    final lime = scheme.secondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              color: lime,
              child: Icon(
                Icons.explore_outlined,
                color: scheme.onSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Text(
                  'NO RECIPES FOUND',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: 2.0,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 32, height: 2, color: lime),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              provider.hasActiveFilters
                  ? 'No recipes match your current filters. Try clearing them to see more.'
                  : 'Nothing here yet. Try a different search term.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            if (provider.hasActiveFilters) ...[
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () {
                  HapticService.lightImpact();
                  provider.clearFilters();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 11, horizontal: 28),
                  decoration: BoxDecoration(
                    color: lime,
                  ),
                  child: Text(
                    'CLEAR FILTERS',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      color: scheme.onSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
