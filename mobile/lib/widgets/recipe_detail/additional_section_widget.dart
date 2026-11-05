import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/theme/theme.dart';

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
    final lime = Theme.of(context).colorScheme.secondary;
    final changeColor = Theme.of(context).colorScheme.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags
        if (tags != null && tags!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TAGS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: updatedFields.contains('tags')
                        ? changeColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 28, height: 3, color: lime),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1.5,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags!.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Description
        if (description != null && description!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESCRIPTION',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: updatedFields.contains('description')
                        ? changeColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 28, height: 3, color: lime),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1.5,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              description!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: updatedFields.contains('description')
                    ? changeColor
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontStyle: updatedFields.contains('description')
                    ? FontStyle.italic
                    : null,
              ),
            ),
          ),
        ],

        // Notes
        if (notes != null && notes!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOTES',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: updatedFields.contains('notes')
                        ? changeColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 28, height: 3, color: lime),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1.5,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: lime,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
            child: Text(
              notes!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: updatedFields.contains('notes')
                    ? changeColor
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontStyle: updatedFields.contains('notes')
                    ? FontStyle.italic
                    : null,
              ),
            ),
          ),
        ],

        const SizedBox(height: 64),
      ],
    );
  }
}
