import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/pages/create_recipe_page.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';
import 'package:i_cant_cook/widgets/recipes/recipe_tile.dart';
import 'package:i_cant_cook/widgets/skeletons/skeletons.dart';
import 'package:i_cant_cook/providers/user_recipes_provider.dart';
import 'package:provider/provider.dart';

class RecipesPage extends StatefulWidget {
  final void Function(int)? onNavigateToTab;

  const RecipesPage({super.key, this.onNavigateToTab});

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
                HapticService.mediumImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  builder: (_) => const CreateRecipePage(),
                ).then((_) {
                  if (mounted) {
                    Provider.of<UserRecipesProvider>(context, listen: false)
                        .fetchRecipes();
                  }
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
                  _buildSearchBar(context, provider),
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
                    if (!provider.hasLoaded) {
                      return RecipesListSkeleton(tileMode: provider.tileMode);
                    }
                    if (provider.tabIndex == 3 &&
                        provider.selectedTag == null) {
                      return _buildTagsGrid(context, provider);
                    }
                    if (provider.allRecipes.isEmpty) {
                      return _buildFirstTimeEmptyState(context);
                    }
                    if (provider.filteredRecipes.isEmpty) {
                      return _buildNoResultsState(context);
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: CurvedAnimation(
                            parent: animation, curve: Curves.easeOut),
                        child: child,
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(
                            '${provider.tileMode}_${provider.tabIndex}_${provider.selectedTag}'),
                        child: SlidableAutoCloseBehavior(
                          child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: provider.filteredRecipes.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0)
                              return _buildListHeader(context, provider);
                            final recipe = provider.filteredRecipes[index - 1];
                            final itemIndex = index - 1;
                            return _buildRecipeTile(recipe)
                                .animate(
                                  delay: (itemIndex < 12 ? itemIndex * 30 : 0).ms,
                                )
                                .fadeIn(duration: 200.ms)
                                .slideY(
                                  begin: 0.05,
                                  curve: Curves.easeOut,
                                  duration: 200.ms,
                                );
                          },
                        )),
                      ),
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

  Widget _buildSearchBar(BuildContext context, UserRecipesProvider provider) {
    final isTagSearch = provider.tabIndex == 3 && provider.selectedTag == null;

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
          controller: provider.searchController,
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
            hintText: isTagSearch ? 'Search tags…' : 'Search recipes…',
            hintStyle: GoogleFonts.spaceGrotesk(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
              fontSize: 15,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          ),
          onChanged: isTagSearch
              ? provider.onTagSearchChanged
              : provider.onSearchTextChanged,
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
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.selectionClick();
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                child: isSelected
                    ? Container(
                        color: const Color(0xFFCAFF00),
                        padding: const EdgeInsets.fromLTRB(4, 7, 4, 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tabs[i],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: const Color(0xFF0A0A0A),
                              ),
                            ),
                            
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(
                          tabs[i],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.35),
                          ),
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
    if (provider.filteredUserTags.isEmpty) {
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
      crossAxisCount: 3,
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      childAspectRatio: 1.2,
      padding: EdgeInsets.zero,
      children: provider.filteredUserTags.map((tag) {
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
                fontSize: 13,
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
                onTap: () {
                  HapticService.selectionClick();
                  provider.setTileMode(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(left: 6),
                  color: isActive
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  child: Icon(
                    icons[i],
                    size: 24,
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

  // ── Empty states ─────────────────────────────────────────────────────

  Widget _buildFirstTimeEmptyState(BuildContext context) {
    const lime = Color(0xFFCAFF00);
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              width: 56,
              height: 56,
              color: lime,
              child: const Icon(
                Icons.menu_book,
                color: Color(0xFF0A0A0A),
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Text(
                  'NO RECIPES YET',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 2.5,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 32, height: 2, color: lime),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Start cooking! Create your first recipe, browse the community, or ask CookBot for inspiration.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: scheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              context,
              label: 'CREATE RECIPE',
              icon: Icons.add,
              filled: true,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                builder: (_) => const CreateRecipePage(),
              ).then((_) {
                Provider.of<UserRecipesProvider>(context, listen: false)
                    .fetchRecipes();
              }),
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              context,
              label: 'EXPLORE RECIPES',
              icon: Icons.explore_outlined,
              filled: false,
              onTap: () => widget.onNavigateToTab?.call(1),
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              context,
              label: 'ASK COOKBOT',
              icon: Icons.chat_bubble_outline,
              filled: false,
              onTap: () => widget.onNavigateToTab?.call(0),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(
                  color: scheme.outline.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.search_off,
                color: scheme.onSurface.withOpacity(0.4),
                size: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NO RESULTS',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.8,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term or switch tabs.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: scheme.onSurface.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    const lime = Color(0xFFCAFF00);
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        decoration: BoxDecoration(
          color: filled ? lime : Colors.transparent,
          border: filled
              ? null
              : Border.all(
                  color: scheme.outline.withOpacity(0.3),
                  width: 1.5,
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  filled ? const Color(0xFF0A0A0A) : scheme.onSurface,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.1,
                color: filled
                    ? const Color(0xFF0A0A0A)
                    : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
