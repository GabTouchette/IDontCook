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
    final hasData = _hasNutritionData();
    // Debug logging
    // ignore: avoid_print
    print(
        '[NutritionInfo] build: recipeId=${recipe.id} servings=$servings calories=${recipe.calories} protein=${recipe.protein} fat=${recipe.fat} carbs=${recipe.carbs} hasData=$hasData');
    if (!hasData) {
      // Return a tiny transparent placeholder so we know build ran
      return const SizedBox.shrink();
    }

    // Model nutrition values are stored PER SINGLE SERVING.
    // We display totals for the currently selected servings by multiplying.
    final totalCalories = _scaleForServings(recipe.calories);
    final totalProtein = _scaleForServings(recipe.protein);
    final totalFat = _scaleForServings(recipe.fat);
    final totalCarbs = _scaleForServings(recipe.carbs);
    final perServingCalories = recipe.calories;
    final perServingProtein = recipe.protein;
    final perServingFat = recipe.fat;
    final perServingCarbs = recipe.carbs;

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
          if (totalCalories != null) ...[
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.fire,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calories',
                          style: GoogleFonts.nunito(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (perServingCalories != null && servings > 1)
                          Text(
                            '${perServingCalories.round()} per serving',
                            style: GoogleFonts.nunito(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${totalCalories.round()}',
                        style: GoogleFonts.nunito(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (perServingCalories != null && servings <= 1)
                        Text(
                          'per serving',
                          style: GoogleFonts.nunito(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Macronutrients Row
          Row(
            children: [
              if (totalProtein != null)
                Expanded(
                  child: _buildMacroCard(
                    context,
                    label: 'Protein',
                    totalValue: totalProtein,
                    perServingValue: perServingProtein,
                    unit: 'g',
                    icon: FontAwesomeIcons.dumbbell,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              if (totalProtein != null && totalFat != null)
                const SizedBox(width: 12),
              if (totalFat != null)
                Expanded(
                  child: _buildMacroCard(
                    context,
                    label: 'Fat',
                    totalValue: totalFat,
                    perServingValue: perServingFat,
                    unit: 'g',
                    icon: FontAwesomeIcons.droplet,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (totalFat != null && totalCarbs != null)
                const SizedBox(width: 12),
              if (totalCarbs != null)
                Expanded(
                  child: _buildMacroCard(
                    context,
                    label: 'Carbs',
                    totalValue: totalCarbs,
                    perServingValue: perServingCarbs,
                    unit: 'g',
                    icon: FontAwesomeIcons.wheatAwn,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    BuildContext context, {
    required String label,
    required double totalValue,
    required double? perServingValue,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
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
            '${totalValue.toStringAsFixed(1)}$unit',
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

  double? _scaleForServings(double? perServingValue) {
    if (perServingValue == null) return null;
    return perServingValue *
        servings; // multiply because stored value is per single serving
  }
}
