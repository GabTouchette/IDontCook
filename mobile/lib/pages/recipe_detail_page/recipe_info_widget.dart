import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/utils/functions.dart';

class RecipeInfo extends StatelessWidget {
  final Recipe recipe;
  final int servings;
  final List<bool> completedInstructions;
  final Function incrementServings;
  final Function decrementServings;
  final Function onCompletedInstructions;
  final Set<String> updatedFields;

  const RecipeInfo({
    Key? key,
    required this.recipe,
    required this.servings,
    required this.incrementServings,
    required this.decrementServings,
    required this.completedInstructions,
    required this.onCompletedInstructions,
    required this.updatedFields,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16),
          child: Text(
            recipe.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 36,
              color: ColorPalette.offWhite,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              if (recipe.preparation_time != null) ...[
                const Icon(Icons.timer, size: 20, color: ColorPalette.yellow),
                const SizedBox(width: 6),
                Text(
                  'Prep: ${recipe.preparation_time} min',
                  style: TextStyle(
                    color: updatedFields.contains("preparation_time")
                        ? ColorPalette.mustard
                        : ColorPalette.offWhite,
                    fontSize: 16,
                  ),
                ),
              ],
              if (recipe.cooking_time != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.local_fire_department,
                    size: 20, color: ColorPalette.orange),
                const SizedBox(width: 6),
                Text(
                  'Cook: ${recipe.cooking_time} min',
                  style: TextStyle(
                    color: updatedFields.contains("cooking_time")
                        ? ColorPalette.mustard
                        : ColorPalette.offWhite,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Serves: ',
                style: TextStyle(
                  color: updatedFields.contains("servings")
                      ? ColorPalette.mustard
                      : ColorPalette.offWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.remove, color: ColorPalette.offWhite),
                  onPressed: () => decrementServings()),
              Text('$servings',
                  style: TextStyle(color: ColorPalette.offWhite, fontSize: 18)),
              IconButton(
                  icon: const Icon(Icons.add, color: ColorPalette.offWhite),
                  onPressed: () => incrementServings()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 20, bottom: 12),
          child: Text(
            "Ingredients",
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: recipe.ingredients.map((ingredient) {
              double adjustedQuantity = adjustQuantityForServings(
                  ingredient.quantity ?? 0, recipe.servings ?? 1, servings);
              String formattedIngredient =
                  "${formatQuantity(adjustedQuantity)} ${ingredient.name ?? ''}"
                      .trim();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Container(
                  child: Text(
                    "- $formattedIngredient",
                    style: TextStyle(
                      color: updatedFields.contains("ingredients")
                          ? ColorPalette.mustard
                          : ColorPalette.offWhite,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 24.0),
          child: Text(
            "Instructions",
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              recipe.instructions.length,
              (index) {
                final isCompleted = (index < completedInstructions.length)
                    ? completedInstructions[index]
                    : false;
                return GestureDetector(
                  onTap: () => onCompletedInstructions(index),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                isCompleted ? Colors.green : Colors.grey,
                            child: isCompleted
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recipe.instructions[index],
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.green
                                    : ColorPalette.offWhite,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.grey),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
