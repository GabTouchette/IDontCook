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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAGS',
            style: GoogleFonts.spaceGrotesk(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 28, height: 2, color: const Color(0xFFCAFF00)),
          const SizedBox(height: 16),
          _buildMealTypeSection(),
          const SizedBox(height: 4),
          ...tagOptions.entries
              .where((entry) => entry.key != 'Meal Types')
              .map((entry) => _buildExpandableCategory(
                    context,
                    category: entry.key,
                    tags: entry.value,
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildExpandableCategory(
    BuildContext context, {
    required String category,
    required List<String> tags,
  }) {
    final isExpanded = _expansionStates[category] ?? false;
    final selectedTags = widget.selectedTags;
    final categorySelectedCount = tags
        .where((tag) =>
            selectedTags.any((t) => t.toLowerCase() == tag.toLowerCase()))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          thickness: 1,
          height: 1,
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            final opening = !isExpanded;
            // Close all other sections when opening this one
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
                        color: const Color(0xFFCAFF00),
                        child: Text(
                          '$categorySelectedCount',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF0A0A0A),
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
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        final isSelected = selectedTags.any(
                            (t) => t.toLowerCase() == tag.toLowerCase());
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                widget.selectedTags.removeWhere(
                                    (t) => t.toLowerCase() == tag.toLowerCase());
                              } else {
                                widget.selectedTags.add(tag);
                              }
                              widget.onTagsChanged(widget.selectedTags);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
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
                                fontSize: 13,
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

  Widget _buildMealTypeSection() {
    final selectedMealType = _getSelectedMealType();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'MEAL TYPE',
              style: GoogleFonts.spaceGrotesk(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '* required',
              style: GoogleFonts.spaceGrotesk(
                color: Theme.of(context)
                    .colorScheme
                    .error
                    .withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: mealTypes.map((mealType) {
            final isSelected = selectedMealType == mealType;
            return GestureDetector(
              onTap: () => _setMealType(mealType),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                    width: 1.5,
                  ),
                ),
                child: Text(
                  mealType,
                  style: GoogleFonts.spaceGrotesk(
                    color: isSelected
                        ? const Color(0xFF0A0A0A)
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
