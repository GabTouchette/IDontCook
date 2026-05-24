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

  @override
  void initState() {
    super.initState();
    _usedTagsFuture = fetchRecipeTags();
  }

  Future<Map<String, List<String>>> fetchRecipeTags() async {
    try {
      var data = await RecipeApi().fetchRecipeTags();
      print('Fetched recipe tags: $data');

      // Filter tagOptions to only include used tags, preserving category structure
      Map<String, List<String>> filteredTags = {};
      tagOptions.forEach((category, tags) {
        final usedCategoryTags =
            tags.where((tag) => data.contains(tag)).toList();
        if (usedCategoryTags.isNotEmpty) {
          filteredTags[category] = usedCategoryTags;
        }
      });

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

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          // Fallback to showing all tags if there's an error
          return _buildTagFilters(tagOptions);
        }

        return _buildTagFilters(snapshot.data!);
      },
    );
  }

  Widget _buildTagFilters(Map<String, List<String>> tagsByCategory) {
    final entries = tagsByCategory.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < entries.length; i++) ...
          [
            _CategoryFilter(category: entries[i].key, tags: entries[i].value),
            if (i < entries.length - 1)
              Divider(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                thickness: 1,
                height: 1,
              ),
          ],
      ],
    );
  }
}

// Keep your existing _CategoryFilter widget as is
class _CategoryFilter extends StatelessWidget {
  final String category;
  final List<String> tags;

  const _CategoryFilter({required this.category, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        final selectedTags = provider.filters['selectedTags'] ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(width: 18, height: 2, color: const Color(0xFFCAFF00)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: tags.map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      final updatedTags = List<String>.from(selectedTags);
                      isSelected ? updatedTags.remove(tag) : updatedTags.add(tag);
                      provider.updateFilter('selectedTags', updatedTags);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFCAFF00)
                            : Colors.transparent,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFCAFF00)
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
                              ? const Color(0xFF0A0A0A)
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
            ],
          ),
        );
      },
    );
  }
}
