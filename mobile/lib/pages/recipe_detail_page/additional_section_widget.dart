import 'package:flutter/material.dart';
import 'package:mobile/theme/colors.dart';

class AdditionalSections extends StatelessWidget {
  final List<String>? tags;
  final String? description;
  final String? notes;

  const AdditionalSections({
    Key? key,
    this.tags,
    this.description,
    this.notes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags != null && tags!.isNotEmpty) _buildTagSection(tags!),
        if (description != null && description!.isNotEmpty) _buildSection("Description", description!),
        if (notes != null && notes!.isNotEmpty) _buildSection("Notes", notes!),
        const SizedBox(height: 64),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(color: ColorPalette.offWhite, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTagSection(List<String> tags) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tags", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: ColorPalette.darkgray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(tag, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
