import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/theme/theme.dart';
import 'package:i_cant_cook/utils/functions.dart';

class IngredientsSection extends StatefulWidget {
  final Recipe recipe;
  final double servings;
  final Set<String> updatedFields;
  final List<bool> completedIngredients;
  final Function onCompletedIngredient;
  final Map<int, double> ingredientCalories;

  const IngredientsSection({
    Key? key,
    required this.recipe,
    required this.servings,
    required this.completedIngredients,
    required this.onCompletedIngredient,
    required this.updatedFields,
    this.ingredientCalories = const {},
  }) : super(key: key);

  @override
  State<IngredientsSection> createState() => _IngredientsSectionState();
}

class _IngredientsSectionState extends State<IngredientsSection> {
  @override
  Widget build(BuildContext context) {
    final isUpdated = widget.updatedFields.contains('ingredients');
    const lime = Color(0xFFCAFF00);
    final changeColor = Theme.of(context).colorScheme.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'INGREDIENTS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: isUpdated
                          ? changeColor
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.recipe.ingredients.length}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(width: 28, height: 3, color: lime),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 1.5,
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
        ),

        // Ingredients list
        ...widget.recipe.ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          final isCompleted = index < widget.completedIngredients.length
              ? widget.completedIngredients[index]
              : false;
          final display = resolveIngredientDisplay(
            dbQuantity: ingredient.quantity ?? 0,
            dbUnit: ingredient.unit ?? '',
            dbName: ingredient.name ?? '',
            servings: widget.servings,
            baseServings: (widget.recipe.servings ?? 1).toDouble(),
          );
          final calStr = (ingredient.id != null &&
                  widget.ingredientCalories.containsKey(ingredient.id))
              ? '${widget.ingredientCalories[ingredient.id]!.round()} cal'
              : null;

          return GestureDetector(
            onTap: () {
              HapticService.selectionClick();
              widget.onCompletedIngredient(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: isCompleted
                  ? const Color(0xFFCAFF00).withOpacity(0.06)
                  : Colors.transparent,
              child: Column(
                children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Quantity + unit block
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${display.qty}${display.unit.isNotEmpty ? ' ${display.unit}' : ''}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isCompleted
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.3)
                                : isUpdated
                                    ? changeColor
                                    : Theme.of(context).colorScheme.onSurface,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            fontStyle: isUpdated && !isCompleted
                                ? FontStyle.italic
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Ingredient name
                      Expanded(
                        child: Text(
                          display.name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: isCompleted
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.3)
                                : isUpdated
                                    ? changeColor
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            fontStyle: isUpdated && !isCompleted
                                ? FontStyle.italic
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Calorie badge
                      if (calStr != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            calStr,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.35),
                            ),
                          ),
                        ),
                      // Checkmark
                      if (isCompleted)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
                ),
              ],
            ),
          ),
        );
        }).toList(),
      ],
    );
  }
}
