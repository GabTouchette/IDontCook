import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
        // Tags Section
        if (tags != null && tags!.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorPalette.darkgray,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: ColorPalette.lightgray.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.tags,
                      color: ColorPalette.yellow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tags',
                      style: GoogleFonts.nunito(
                        color: updatedFields.contains("tags")
                            ? ColorPalette.mustard
                            : ColorPalette.offWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorPalette.yellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: ColorPalette.yellow.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${tags!.length} tags',
                        style: const TextStyle(
                          color: ColorPalette.yellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: tags!.map((tag) {
                    final isHighlighted = updatedFields.contains("tags");
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: ColorPalette.yellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isHighlighted
                              ? ColorPalette.mustard.withOpacity(0.5)
                              : ColorPalette.yellow.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.label,
                            size: 14,
                            color: isHighlighted
                                ? ColorPalette.mustard
                                : ColorPalette.yellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tag,
                            style: TextStyle(
                              color: isHighlighted
                                  ? ColorPalette.mustard
                                  : ColorPalette.yellow,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Description Section
        if (description != null && description!.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorPalette.darkgray,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: ColorPalette.lightgray.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.fileLines,
                      color: ColorPalette.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Description',
                      style: TextStyle(
                        color: updatedFields.contains("description")
                            ? ColorPalette.mustard
                            : ColorPalette.offWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.darkergray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: updatedFields.contains("description")
                          ? ColorPalette.mustard.withOpacity(0.3)
                          : ColorPalette.lightgray.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    description!,
                    style: GoogleFonts.inter(
                      color: updatedFields.contains("description")
                          ? ColorPalette.mustard
                          : ColorPalette.offWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Notes Section
        if (notes != null && notes!.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorPalette.darkgray,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: ColorPalette.lightgray.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.noteSticky,
                      color: ColorPalette.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Notes',
                      style: TextStyle(
                        color: updatedFields.contains("notes")
                            ? ColorPalette.mustard
                            : ColorPalette.offWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: updatedFields.contains("notes")
                          ? ColorPalette.mustard.withOpacity(0.3)
                          : ColorPalette.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: ColorPalette.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes!,
                          style: TextStyle(
                            color: updatedFields.contains("notes")
                                ? ColorPalette.mustard
                                : ColorPalette.offWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
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
