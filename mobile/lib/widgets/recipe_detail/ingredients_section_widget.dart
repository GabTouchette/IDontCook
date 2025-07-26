import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/utils/functions.dart';

class IngredientsSection extends StatelessWidget {
  final Recipe recipe;
  final int servings;
  final Set<String> updatedFields;

  const IngredientsSection({
    Key? key,
    required this.recipe,
    required this.servings,
    required this.updatedFields,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          // Header
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.listUl,
                color: ColorPalette.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ingredients',
                style: GoogleFonts.nunito(
                  color: updatedFields.contains("ingredients")
                      ? ColorPalette.mustard
                      : ColorPalette.offWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorPalette.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: ColorPalette.green.withOpacity(0.3)),
                ),
                child: Text(
                  '${recipe.ingredients.length} items',
                  style: const TextStyle(
                    color: ColorPalette.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ingredients List
          ...recipe.ingredients.map((ingredient) {
            double adjustedQuantity = adjustQuantityForServings(
                ingredient.quantity ?? 0, recipe.servings ?? 1, servings);
            String formattedIngredient =
                "${formatQuantity(adjustedQuantity)}${ingredient.unit != null && ingredient.unit!.isNotEmpty ? ' ${ingredient.unit?.toLowerCase()}' : ''} ${ingredient.name?.toLowerCase() ?? ''}"
                    .trim();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorPalette.darkergray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: updatedFields.contains("ingredients")
                      ? ColorPalette.mustard.withOpacity(0.3)
                      : ColorPalette.lightgray.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ColorPalette.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formattedIngredient,
                      style: TextStyle(
                        color: updatedFields.contains("ingredients")
                            ? ColorPalette.mustard
                            : ColorPalette.offWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Show nutrition info if available
                  if (ingredient.nutrition != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.info_outline,
                      color: ColorPalette.lightgray,
                      size: 16,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
