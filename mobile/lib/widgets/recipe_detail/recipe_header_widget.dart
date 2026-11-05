import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/theme.dart';

class RecipeHeader extends StatelessWidget {
  final Recipe recipe;
  final double servings;
  final Function incrementServings;
  final Function decrementServings;
  final Set<String> updatedFields;

  const RecipeHeader({
    Key? key,
    required this.recipe,
    required this.servings,
    required this.incrementServings,
    required this.decrementServings,
    required this.updatedFields,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    // This bar intentionally inverts relative to theme brightness (near-black
    // bar w/ pale text in light mode, pale bar w/ near-black text in dark
    // mode), so it maps to onSurface/onSecondary per-branch rather than a
    // single token.
    final barBg = isDark ? const Color(0xFFF5F4EF) : cs.onSurface;
    final barText = isDark ? cs.onSecondary : const Color(0xFFF5F4EF);
    final changeColor = Theme.of(context).colorScheme.success;

    final stats = <_StatItem>[];
    if (recipe.preparation_time != null) {
      stats.add(_StatItem(
        value: '${recipe.preparation_time}',
        label: 'PREP',
        unit: 'MIN',
        highlighted: updatedFields.contains('preparation_time'),
      ));
    }
    if (recipe.cooking_time != null) {
      stats.add(_StatItem(
        value: '${recipe.cooking_time}',
        label: 'COOK',
        unit: 'MIN',
        highlighted: updatedFields.contains('cooking_time'),
      ));
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: barBg,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 44,
                color: barText.withOpacity(0.2),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stats[i].label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: stats[i].highlighted
                          ? changeColor
                          : barText.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        stats[i].value,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: stats[i].highlighted ? changeColor : barText,
                          height: 1.0,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        stats[i].unit,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: stats[i].highlighted
                              ? changeColor
                              : barText.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem {
  final String value;
  final String label;
  final String unit;
  final bool highlighted;

  const _StatItem({
    required this.value,
    required this.label,
    required this.unit,
    required this.highlighted,
  });
}
