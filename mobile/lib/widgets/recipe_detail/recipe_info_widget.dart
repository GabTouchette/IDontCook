import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/widgets/recipe_detail/recipe_header_widget.dart';
import 'package:i_cant_cook/widgets/recipe_detail/servings_section_widget.dart';
import 'package:i_cant_cook/widgets/recipe_detail/nutrition_info_widget.dart';
import 'package:i_cant_cook/widgets/recipe_detail/ingredients_section_widget.dart';
import 'package:i_cant_cook/widgets/recipe_detail/instructions_section_widget.dart';

class RecipeInfo extends StatelessWidget {
  final Recipe recipe;
  final double servings;
  final List<bool> completedInstructions;
  final List<bool> completedIngredients;
  final Function incrementServings;
  final Function decrementServings;
  final Function onCompletedInstructions;
  final Function onCompletedIngredient;
  final Set<String> updatedFields;
  final Map<int, double> ingredientCalories;

  const RecipeInfo({
    Key? key,
    required this.recipe,
    required this.servings,
    required this.incrementServings,
    required this.decrementServings,
    required this.completedInstructions,
    required this.completedIngredients,
    required this.onCompletedInstructions,
    required this.onCompletedIngredient,
    required this.updatedFields,
    this.ingredientCalories = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe Header (Title and Times)
        RecipeHeader(
          recipe: recipe,
          servings: servings,
          incrementServings: incrementServings,
          decrementServings: decrementServings,
          updatedFields: updatedFields,
        ),

        // Servings Section
        ServingsSection(
          servings: servings,
          incrementServings: incrementServings,
          decrementServings: decrementServings,
          updatedFields: updatedFields,
        ),

        // Nutrition Info (moved here to appear right after servings)
        NutritionInfo(
          recipe: recipe,
          servings: servings,
        ),

        // Ingredients Section
        IngredientsSection(
          recipe: recipe,
          servings: servings,
          completedIngredients: completedIngredients,
          onCompletedIngredient: onCompletedIngredient,
          updatedFields: updatedFields,
          ingredientCalories: ingredientCalories,
        ),

        // Instructions Section
        InstructionsSection(
          recipe: recipe,
          completedInstructions: completedInstructions,
          onCompletedInstructions: onCompletedInstructions,
          updatedFields: updatedFields,
        ),
      ],
    );
  }
}
