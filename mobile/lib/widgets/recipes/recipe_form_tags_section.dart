import 'package:flutter/material.dart';
import 'package:mobile/utils/constants.dart';
import 'package:mobile/theme/colors.dart';

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
  String? _selectedTag;
  String? _currentlyExpandedCategory;

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
          SizedBox(height: 8.0),
          Container(
            decoration: BoxDecoration(
              color: ColorPalette.lightgray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                _showHierarchicalDropdown(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTag ?? 'Select Tag',
                      style: TextStyle(
                        color:
                            _selectedTag == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: widget.selectedTags.map((tag) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    widget.selectedTags.remove(tag);
                    widget.onTagsChanged(widget.selectedTags);
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: ColorPalette.darkgray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 6.0),
                      Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showHierarchicalDropdown(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (var category in tagOptions.keys)
                  ExpansionTile(
                    title: Text(category),
                    initiallyExpanded: _currentlyExpandedCategory == category,
                    onExpansionChanged: (isExpanded) {
                      setState(() {
                        if (isExpanded) {
                          _currentlyExpandedCategory = category;
                        } else {
                          _currentlyExpandedCategory = null;
                        }
                      });
                    },
                    children: [
                      for (var tag in tagOptions[category]!)
                        Padding(
                          padding: const EdgeInsets.only(left: 24.0),
                          child: ListTile(
                            title: Text(tag),
                            onTap: () {
                              setState(() {
                                _selectedTag = tag;
                                if (!widget.selectedTags.contains(tag)) {
                                  widget.selectedTags.add(tag);
                                }
                                widget.onTagsChanged(widget.selectedTags);
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
