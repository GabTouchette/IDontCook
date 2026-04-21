import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/utils/constants.dart';

class TagsSection extends StatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagsSection({
    Key? key,
    required this.selectedTags,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  _TagsSectionState createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  // Required meal type tags
  final List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert'
  ];

  // Track expansion state for each category
  Map<String, bool> _expansionStates = {};

  String _getSelectedMealType() {
    for (String mealType in mealTypes) {
      if (widget.selectedTags
          .any((tag) => tag.toLowerCase() == mealType.toLowerCase())) {
        return mealType;
      }
    }
    return 'Dinner'; // Default fallback
  }

  void _setMealType(String newMealType) {
    setState(() {
      // Remove all existing meal types
      widget.selectedTags.removeWhere((tag) => mealTypes
          .any((mealType) => tag.toLowerCase() == mealType.toLowerCase()));

      // Add the new meal type
      widget.selectedTags.add(newMealType);
      widget.onTagsChanged(widget.selectedTags);
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize expansion states - start with meal types always expanded (required), others collapsed
    _expansionStates = {
      for (String category in tagOptions.keys.where((k) => k != "Meal Types"))
        category: false, // Start other categories collapsed
    };

    // Ensure there's always a meal type selected - default to Dinner if none
    if (!mealTypes.any((mealType) => widget.selectedTags
        .any((tag) => tag.toLowerCase() == mealType.toLowerCase()))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setMealType('Dinner');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tags",
              style: GoogleFonts.nunito(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16.0),

            // Meal Type Section (Radio Button Style)
            _buildMealTypeSection(),
            const SizedBox(height: 24.0),

            // Other tag categories (collapsible sections)
            ...tagOptions.entries
                .where((entry) => entry.key != "Meal Types")
                .map((entry) {
              final category = entry.key;
              final tags = entry.value;
              final isExpanded = _expansionStates[category] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: ExpansionTile(
                  title: Text(
                    category,
                    style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expansionStates[category] = expanded;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: tags.map((tag) {
                          final isSelected = widget.selectedTags.any(
                              (selectedTag) =>
                                  selectedTag.toLowerCase() ==
                                  tag.toLowerCase());
                          return Container(
                            margin: const EdgeInsets.only(right: 8, bottom: 8),
                            child: FilterChip(
                              showCheckmark: false,
                              label: Text(tag),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    widget.selectedTags.add(tag);
                                  } else {
                                    widget.selectedTags.remove(tag);
                                  }
                                  widget.onTagsChanged(widget.selectedTags);
                                });
                              },
                              selectedColor:
                                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              side: BorderSide(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
                                    : Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.3),
                                width: 1.5,
                              ),
                              elevation: isSelected ? 2 : 0,
                              shadowColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              labelStyle: GoogleFonts.nunito(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSection() {
    final selectedMealType = _getSelectedMealType();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Meal Type",
              style: GoogleFonts.nunito(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                "Required",
                style: GoogleFonts.nunito(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: mealTypes.map((mealType) {
            final isSelected = selectedMealType == mealType;
            return GestureDetector(
              onTap: () => _setMealType(mealType),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Icons.radio_button_checked,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      Icon(
                        Icons.radio_button_unchecked,
                        size: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      mealType,
                      style: GoogleFonts.nunito(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
