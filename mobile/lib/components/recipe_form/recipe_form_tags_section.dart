import 'package:flutter/material.dart';
import 'package:mobile/theme/colors.dart';

class TagsSection extends StatefulWidget {
  final List<String> tagOptions;
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagsSection({
    Key? key,
    required this.tagOptions,
    required this.selectedTags,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  _TagsSectionState createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  String? _selectedTag;

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
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: ColorPalette.lightgray,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            hint: Text('Select tags'),
            value: _selectedTag,
            onChanged: (String? newValue) {
              setState(() {
                _selectedTag = newValue;
                if (_selectedTag != null &&
                    !widget.selectedTags.contains(_selectedTag)) {
                  widget.selectedTags.add(_selectedTag!);
                }
                widget.onTagsChanged(widget.selectedTags);
              });
            },
            items: widget.tagOptions.map((String tag) {
              return DropdownMenuItem<String>(
                value: tag,
                child: Text(tag),
              );
            }).toList(),
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
}
