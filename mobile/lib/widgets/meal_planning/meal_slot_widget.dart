import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';

class MealSlot extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? title;
  final String? thumbnailUrl;
  final VoidCallback? onRemove; // shows an X button when provided and slot filled

  const MealSlot({super.key, required this.label, required this.onTap, this.onLongPress, this.title, this.thumbnailUrl, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isEmpty = title == null || title!.isEmpty;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: isEmpty
          ? DottedBorder(
              color: Theme.of(context).colorScheme.outline,
              strokeWidth: 1.5,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                          style: BorderStyle.solid,
                          width: 1,
                        ),
                      ),
                      child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to select a recipe',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(thumbnailUrl!, fit: BoxFit.cover),
                          )
                        : Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        )
                      ],
                    ),
                  ),
                  if (onRemove != null)
                    IconButton(
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      tooltip: 'Remove',
                      onPressed: onRemove,
                    )
                ],
              ),
            ),
    );
  }
}
