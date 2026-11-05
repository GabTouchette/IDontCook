import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';

/// Renders a `recipe_update` block: a summary of the recipe fields the
/// assistant changed (`{"recipe_id": 123, "changes": {...}}`).
class RecipeUpdateCard extends StatelessWidget {
  final int recipeId;
  final Map<String, dynamic> changes;

  const RecipeUpdateCard({
    super.key,
    required this.recipeId,
    required this.changes,
  });

  static const int _maxVisibleChanges = 6;

  @override
  Widget build(BuildContext context) {
    final entries = changes.entries.toList();
    final visible = entries.take(_maxVisibleChanges).toList();
    final hiddenCount = entries.length - visible.length;
    final mutedColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
      decoration: blockCardDecoration(context, outlineOpacity: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                color: kBlockAccent(context),
                child: Icon(
                  Icons.edit_outlined,
                  color: kBlockAccentInk(context),
                  size: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'RECIPE UPDATED',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: mutedColor,
                ),
              ),
            ],
          ),
          if (visible.isNotEmpty) const SizedBox(height: 10),
          ...visible.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '– ${_labelFor(entry.key)}: ${_formatValue(entry.value)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (hiddenCount > 0)
            Text(
              '+ $hiddenCount more change${hiddenCount == 1 ? '' : 's'}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: mutedColor,
              ),
            ),
        ],
      ),
    );
  }

  String _labelFor(String key) => key.replaceAll('_', ' ');

  String _formatValue(dynamic value) {
    if (value == null) return 'removed';
    if (value is List) {
      return '${value.length} item${value.length == 1 ? '' : 's'}';
    }
    if (value is Map) return 'updated';
    final text = value.toString();
    return text.length > 80 ? '${text.substring(0, 80)}…' : text;
  }
}
