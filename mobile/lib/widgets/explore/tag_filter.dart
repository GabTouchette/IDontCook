import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
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
          return const Center(child: CircularProgressIndicator());
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(
                  color: ColorPalette.offWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: tags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    final updatedTags = List<String>.from(selectedTags);
                    selected ? updatedTags.add(tag) : updatedTags.remove(tag);
                    provider.updateFilter('selectedTags', updatedTags);
                  },
                  selectedColor: ColorPalette.lightgray,
                  backgroundColor: ColorPalette.darkgray,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? ColorPalette.darkgray
                        : ColorPalette.placeholdergray,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
