import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';

class MealSlot extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? title;
  final String? thumbnailUrl;
  final VoidCallback?
      onRemove; // shows an X button when provided and slot filled
  final bool isLowQuality; // indicates if this slot has a low fitness score
  final String? emptyReason; // reason why slot couldn't be filled

  const MealSlot({
    super.key,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.title,
    this.thumbnailUrl,
    this.onRemove,
    this.isLowQuality = false,
    this.emptyReason,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = title == null || title!.isEmpty;

    // Determine colors and styling based on state
    Color borderColor;
    Color backgroundColor;
    String displayText;
    IconData iconData;
    Color iconColor;

    if (isEmpty) {
      if (emptyReason != null) {
        // Couldn't fill this slot - show warning
        borderColor = Theme.of(context).colorScheme.secondary.withOpacity(0.7);
        backgroundColor = Theme.of(context).colorScheme.secondary.withOpacity(0.05);
        displayText = emptyReason!;
        iconData = Icons.warning_amber;
        iconColor = Theme.of(context).colorScheme.secondary;
      } else {
        // Normal empty slot
        borderColor = Theme.of(context).colorScheme.outline;
        backgroundColor = Colors.transparent;
        displayText = 'Tap to select a recipe';
        iconData = Icons.add;
        iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
      }
    } else {
      // Filled slot - check quality
      if (isLowQuality) {
        borderColor = Colors.amber.withOpacity(0.8);
        backgroundColor = Theme.of(context).colorScheme.surface;
      } else {
        borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.2);
        backgroundColor = Theme.of(context).colorScheme.surface;
      }
      displayText = title!;
      iconData = Icons.image_outlined;
      iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: isEmpty
          ? DottedBorder(
              color: borderColor,
              strokeWidth: 1.5,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: backgroundColor,
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
                          color: borderColor.withOpacity(0.6),
                          style: BorderStyle.solid,
                          width: 1,
                        ),
                      ),
                      child: Icon(iconData, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (emptyReason != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: emptyReason != null
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.shadow.withOpacity(0.06),
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
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(iconData, color: iconColor),
                            ),
                          )
                        : Icon(iconData, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isLowQuality)
                              Tooltip(
                                message:
                                    'This recipe may not fully match your preferences',
                                child: Icon(
                                  Icons.warning_amber,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayText,
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
                      icon: Icon(Icons.close,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      tooltip: 'Remove',
                      onPressed: onRemove,
                    )
                ],
              ),
            ),
    );
  }
}
