import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/colors.dart';

class RecipeHeader extends StatelessWidget {
  final Recipe recipe;
  final int servings;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe Title (no container)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            recipe.title,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: ColorPalette.offWhite,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Time Information Row (no container)
        if (recipe.preparation_time != null || recipe.cooking_time != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                if (recipe.preparation_time != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColorPalette.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: ColorPalette.yellow.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.clock,
                          size: 14,
                          color: ColorPalette.yellow,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Prep: ${recipe.preparation_time}m',
                          style: GoogleFonts.nunito(
                            color: updatedFields.contains("preparation_time")
                                ? ColorPalette.mustard
                                : ColorPalette.yellow,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (recipe.preparation_time != null &&
                    recipe.cooking_time != null)
                  const SizedBox(width: 12),
                if (recipe.cooking_time != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColorPalette.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: ColorPalette.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.fire,
                          size: 14,
                          color: ColorPalette.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cook: ${recipe.cooking_time}m',
                          style: GoogleFonts.nunito(
                            color: updatedFields.contains("cooking_time")
                                ? ColorPalette.mustard
                                : ColorPalette.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
