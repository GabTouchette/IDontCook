import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/utils/functions.dart';

class IngredientsSection extends StatefulWidget {
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
  State<IngredientsSection> createState() => _IngredientsSectionState();
}

class _IngredientsSectionState extends State<IngredientsSection> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.listUl,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ingredients',
                style: GoogleFonts.nunito(
                  color: widget.updatedFields.contains("ingredients")
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3)),
                ),
                child: Text(
                  '${widget.recipe.ingredients.length} items',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ingredients List
          ...widget.recipe.ingredients.map((ingredient) {
            print(
                "Ingredient: ${ingredient.name}, Quantity: ${ingredient.quantity}, Unit: ${ingredient.unit}");
            print("calories: ${ingredient.nutrition}");
            double adjustedQuantity = adjustQuantityForServings(
                ingredient.quantity ?? 0, widget.recipe.servings ?? 1, widget.servings);
            String formattedIngredient =
                "${formatQuantity(adjustedQuantity)}${ingredient.unit != null && ingredient.unit!.isNotEmpty ? ' ${ingredient.unit?.toLowerCase()}' : ''} ${ingredient.name?.toLowerCase() ?? ''}"
                    .trim();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.updatedFields.contains("ingredients")
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.updatedFields.contains("ingredients")
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedIngredient,
                          style: GoogleFonts.nunito(
                            color: widget.updatedFields.contains("ingredients")
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
