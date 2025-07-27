import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';

class NutritionSummary extends StatelessWidget {
  final Recipe recipe;
  final bool showLabel;
  final double iconSize;
  final double fontSize;

  const NutritionSummary({
    Key? key,
    required this.recipe,
    this.showLabel = true,
    this.iconSize = 14,
    this.fontSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if nutrition data is available
    if (!_hasNutritionData()) {
      return SizedBox.shrink(); // Don't show anything if no nutrition data
    }

    final calories = recipe.calories;
    final servings = recipe.servings ?? 1;
    final caloriesPerServing = calories != null ? (calories / servings).round() : null;

    return Row(
      children: [
        if (showLabel) ...[
          FaIcon(
            FontAwesomeIcons.chartPie,
            color: Theme.of(context).colorScheme.secondary,
            size: iconSize,
          ),
          const SizedBox(width: 4),
        ],
        if (caloriesPerServing != null) ...[
          FaIcon(
            FontAwesomeIcons.fire,
            color: Theme.of(context).colorScheme.secondary,
            size: iconSize,
          ),
          const SizedBox(width: 2),
          Text(
            '$caloriesPerServing cal',
            style: GoogleFonts.nunito(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        
        // Show protein if available and there's space
        if (recipe.protein != null && recipe.protein! > 0) ...[
          const SizedBox(width: 8),
          FaIcon(
            FontAwesomeIcons.dumbbell,
            color: Theme.of(context).colorScheme.primary,
            size: iconSize - 2,
          ),
          const SizedBox(width: 2),
          Text(
            '${(recipe.protein! / servings).toStringAsFixed(0)}g',
            style: GoogleFonts.nunito(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  bool _hasNutritionData() {
    return recipe.calories != null && recipe.calories! > 0;
  }
}