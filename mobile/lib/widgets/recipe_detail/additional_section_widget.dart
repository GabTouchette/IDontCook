import 'package:flutter/material.dart';
import 'package:i_cant_cook/theme/colors.dart';

class AdditionalSections extends StatelessWidget {
  final List<String>? tags;
  final String? description;
  final String? notes;
  final Set<String> updatedFields;

  const AdditionalSections({
    Key? key,
    this.tags,
    this.description,
    this.notes,
    required this.updatedFields,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags != null && tags!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tags",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: tags!.map((tag) {
                    final isHighlighted = updatedFields.contains("tags");
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: ColorPalette.darkgray,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isHighlighted
                              ? ColorPalette.mustard
                              : Colors.white,
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        if (description != null && description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Description",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: TextStyle(
                    color: updatedFields.contains("description")
                        ? ColorPalette.mustard
                        : Colors.white,
                    fontWeight: updatedFields.contains("description")
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        if (notes != null && notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Notes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notes!,
                  style: TextStyle(
                    color: updatedFields.contains("notes")
                        ? ColorPalette.mustard
                        : Colors.white,
                    fontWeight: updatedFields.contains("notes")
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 64),
      ],
    );
  }
}
