import 'package:flutter/material.dart';
import 'package:i_cant_cook/utils/constants.dart';
import 'package:i_cant_cook/theme/colors.dart';

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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tags",
            style: TextStyle(
              color: ColorPalette.offWhite,
              fontWeight: FontWeight.w300,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16.0),
          ...tagOptions.entries.map((entry) {
            final category = entry.key;
            final tags = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    color: ColorPalette.offWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: tags.map((tag) {
                    final isSelected = widget.selectedTags.any((selectedTag) =>
                        selectedTag.toLowerCase() == tag.toLowerCase());
                    return FilterChip(
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
                      selectedColor: ColorPalette.green,
                      backgroundColor: ColorPalette.darkgray,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? ColorPalette.offWhite
                            : ColorPalette.placeholdergray,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
