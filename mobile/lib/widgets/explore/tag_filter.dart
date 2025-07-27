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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tagsByCategory.entries
          .map((entry) => _CategoryFilter(
                category: entry.key,
                tags: entry.value,
              ))
          .toList(),
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

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: tags.map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  return Container(
                    child: GestureDetector(
                      onTap: () {
                        final updatedTags = List<String>.from(selectedTags);
                        isSelected ? updatedTags.remove(tag) : updatedTags.add(tag);
                        provider.updateFilter('selectedTags', updatedTags);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.nunito(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
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
