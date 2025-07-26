import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/colors.dart';

class NutritionInfo extends StatelessWidget {
  final Recipe recipe;
  final int servings;

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
        color: ColorPalette.darkgray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.lightgray.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.chartPie,
                color: ColorPalette.mustard,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Nutrition Per Serving',
                style: GoogleFonts.nunito(
                  color: ColorPalette.offWhite,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorPalette.mustard.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: ColorPalette.mustard.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.fire,
                        color: ColorPalette.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Calories',
                        style: GoogleFonts.nunito(
                          color: ColorPalette.offWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${perServingCalories.round()}',
                    style: GoogleFonts.nunito(
                      color: ColorPalette.mustard,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
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
                    'Protein',
                    perServingProtein,
                    'g',
                    FontAwesomeIcons.dumbbell,
                    ColorPalette.green,
                  ),
                ),
              if (perServingProtein != null && perServingFat != null)
                const SizedBox(width: 8),
              if (perServingFat != null)
                Expanded(
                  child: _buildMacroCard(
                    'Fat',
                    perServingFat,
                    'g',
                    FontAwesomeIcons.droplet,
                    ColorPalette.yellow,
                  ),
                ),
              if (perServingFat != null && perServingCarbs != null)
                const SizedBox(width: 8),
              if (perServingCarbs != null)
                Expanded(
                  child: _buildMacroCard(
                    'Carbs',
                    perServingCarbs,
                    'g',
                    FontAwesomeIcons.wheatAwn,
                    ColorPalette.blue,
                  ),
                ),
            ],
          ),

          // Show total recipe nutrition if more than 1 serving
          if (servings > 1 && _hasAnyNutritionValue()) ...[
            const SizedBox(height: 16),
            const Divider(color: ColorPalette.lightgray),
            const SizedBox(height: 8),
            Text(
              'Total Recipe ($servings servings)',
              style: TextStyle(
                color: ColorPalette.lightgray,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (recipe.calories != null)
                  _buildTotalNutritionItem(
                      '${(recipe.calories! * servings / (recipe.servings ?? 1)).round()}',
                      'cal'),
                if (recipe.protein != null)
                  _buildTotalNutritionItem(
                      '${(recipe.protein! * servings / (recipe.servings ?? 1)).toStringAsFixed(1)}g',
                      'protein'),
                if (recipe.fat != null)
                  _buildTotalNutritionItem(
                      '${(recipe.fat! * servings / (recipe.servings ?? 1)).toStringAsFixed(1)}g',
                      'fat'),
                if (recipe.carbs != null)
                  _buildTotalNutritionItem(
                      '${(recipe.carbs! * servings / (recipe.servings ?? 1)).toStringAsFixed(1)}g',
                      'carbs'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroCard(
      String label, double value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
            style: GoogleFonts.inter(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: ColorPalette.lightgray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalNutritionItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: ColorPalette.offWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: ColorPalette.lightgray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  bool _hasNutritionData() {
    return recipe.calories != null ||
        recipe.protein != null ||
        recipe.fat != null ||
        recipe.carbs != null;
  }

  bool _hasAnyNutritionValue() {
    return (recipe.calories != null && recipe.calories! > 0) ||
        (recipe.protein != null && recipe.protein! > 0) ||
        (recipe.fat != null && recipe.fat! > 0) ||
        (recipe.carbs != null && recipe.carbs! > 0);
  }

  double? _getPerServingValue(double? totalValue) {
    if (totalValue == null) return null;
    final originalServings = recipe.servings ?? 1;
    return (totalValue / originalServings) * (servings / originalServings);
  }
}
