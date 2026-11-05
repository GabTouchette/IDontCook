import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/utils/constants.dart';
import 'package:provider/provider.dart';

class TagFilters extends StatefulWidget {
  const TagFilters();

  @override
  State<TagFilters> createState() => TagFiltersState();
}

class TagFiltersState extends State<TagFilters> {
  late Future<Map<String, List<String>>> _usedTagsFuture;
  final Map<String, bool> _expansionStates = {};

  @override
  void initState() {
    super.initState();
    _usedTagsFuture = fetchRecipeTags();
  }

  Future<Map<String, List<String>>> fetchRecipeTags() async {
    try {
      var data = await RecipeApi().fetchRecipeTags();

      // Match case-insensitively: backend tags are canonicalized, but guard
      // against any lingering casing drift between the DB and the vocabulary.
      final usedLower = data.map((t) => t.toLowerCase()).toSet();

      Map<String, List<String>> filteredTags = {};
      tagOptions.forEach((category, tags) {
        final usedCategoryTags =
            tags.where((tag) => usedLower.contains(tag.toLowerCase())).toList();
        if (usedCategoryTags.isNotEmpty) {
          filteredTags[category] = usedCategoryTags;
        }
      });

      // Initialize expansion states collapsed
      for (final key in filteredTags.keys) {
        _expansionStates[key] = false;
      }

      return filteredTags;
    } catch (e) {
      print('Error fetching recipe tags: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<String>>>(
      future: _usedTagsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        final tagsByCategory = (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)
            ? tagOptions
            : snapshot.data!;

        // Ensure expansion states exist for all categories
        for (final key in tagsByCategory.keys) {
          _expansionStates.putIfAbsent(key, () => false);
        }

        return _buildTagFilters(tagsByCategory);
      },
    );
  }

  Widget _buildTagFilters(Map<String, List<String>> tagsByCategory) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        final lime = Theme.of(context).colorScheme.secondary;
        final ink = Theme.of(context).colorScheme.onSecondary;
        final selectedTags =
            List<String>.from(provider.filters['selectedTags'] ?? []);
        final totalSelected = selectedTags.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TAGS',
                  style: GoogleFonts.spaceGrotesk(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                if (totalSelected > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: lime,
                    child: Text(
                      '$totalSelected',
                      style: GoogleFonts.spaceGrotesk(
                        color: ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            ...tagsByCategory.entries.map((entry) {
              return _buildCollapsibleCategory(
                context,
                provider: provider,
                category: entry.key,
                tags: entry.value,
                selectedTags: selectedTags,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCollapsibleCategory(
    BuildContext context, {
    required ExploreProvider provider,
    required String category,
    required List<String> tags,
    required List<String> selectedTags,
  }) {
    final lime = Theme.of(context).colorScheme.secondary;
    final ink = Theme.of(context).colorScheme.onSecondary;
    final isExpanded = _expansionStates[category] ?? false;
    final categorySelectedCount = tags
        .where((tag) =>
            selectedTags.any((t) => t.toLowerCase() == tag.toLowerCase()))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color:
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          thickness: 1,
          height: 1,
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            final opening = !isExpanded;
            if (opening) {
              for (final key in _expansionStates.keys) {
                _expansionStates[key] = key == category;
              }
            } else {
              _expansionStates[category] = false;
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (categorySelectedCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: lime,
                        child: Text(
                          '$categorySelectedCount',
                          style: GoogleFonts.spaceGrotesk(
                            color: ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: tags.map((tag) {
                        final isSelected = selectedTags.any(
                            (t) => t.toLowerCase() == tag.toLowerCase());
                        return GestureDetector(
                          onTap: () {
                            final updatedTags =
                                List<String>.from(selectedTags);
                            isSelected
                                ? updatedTags.remove(tag)
                                : updatedTags.add(tag);
                            provider.updateFilter(
                                'selectedTags', updatedTags);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? lime
                                  : Colors.transparent,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(
                                color: isSelected
                                    ? lime
                                    : Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.spaceGrotesk(
                                color: isSelected
                                    ? ink
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
