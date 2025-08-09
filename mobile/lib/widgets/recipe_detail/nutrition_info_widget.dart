import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';

class NutritionInfo extends StatelessWidget {
  final Recipe recipe;
  final double servings;

  const NutritionInfo({
    Key? key,
    required this.recipe,
    required this.servings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if nutrition data is available
    if (!_hasNutritionData()) {
      return SizedBox.shrink(); // Don't show anything if no nutrition data
    }

    // Calculate per-serving nutrition
    final perServingCalories = _getPerServingValue(recipe.calories);
    final perServingProtein = _getPerServingValue(recipe.protein);
    final perServingFat = _getPerServingValue(recipe.fat);
    final perServingCarbs = _getPerServingValue(recipe.carbs);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.chartPie,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Nutrition Data',
                style: GoogleFonts.nunito(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calories - Featured prominently
          if (perServingCalories != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.fire,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Calories',
                        style: GoogleFonts.nunito(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${perServingCalories.round()}',
                    style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Macronutrients Row
          Row(
            children: [
              if (perServingProtein != null)
                Expanded(
                  child: _buildMacroCard(
                    context,
                    'Protein',
                    perServingProtein,
                    'g',
                    FontAwesomeIcons.dumbbell,
                    Theme.of(context).colorScheme.secondary,
                  ),
                ),
              if (perServingProtein != null && perServingFat != null)
                const SizedBox(width: 12),
              if (perServingFat != null)
                Expanded(
                  child: _buildMacroCard(
                    context,
                    'Fat',
                    perServingFat,
                    'g',
                    FontAwesomeIcons.droplet,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (perServingFat != null && perServingCarbs != null)
                const SizedBox(width: 12),
              if (perServingCarbs != null)
                Expanded(
                  child: _buildMacroCard(
                    context,
                    'Carbs',
                    perServingCarbs,
                    'g',
                    FontAwesomeIcons.wheatAwn,
                    Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(BuildContext context, String label, double value,
      String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          FaIcon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(1)}$unit',
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasNutritionData() {
    return recipe.calories != null ||
        recipe.protein != null ||
        recipe.fat != null ||
        recipe.carbs != null;
  }

  double? _getPerServingValue(double? totalValue) {
    if (totalValue == null) return null;
    final originalServings = recipe.servings ?? 1;
    // totalValue is total for originalServings; scale linearly by servings
    return (totalValue / originalServings) * servings;
  }
}
