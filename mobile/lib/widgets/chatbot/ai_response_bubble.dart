import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile/models/ingredient.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/chatbot/chat_message.dart';
import 'package:mobile/widgets/chatbot/recipe_card.dart';

class AiResponseBubble extends StatelessWidget {
  final String? message;

  const AiResponseBubble({super.key, this.message});

  Map<String, dynamic>? extractRecipe(String message) {
    final recipeStart = message.indexOf("<recipe>");
    final recipeEnd = message.indexOf("</recipe>");

    if (recipeStart != -1 && recipeEnd != -1) {
      final recipeJson = message.substring(recipeStart + 8, recipeEnd).trim();

      final fixedRecipeJson = recipeJson.replaceAll("'", '"');

      try {
        final recipe = json.decode(fixedRecipeJson);
        final beforeRecipe = message.substring(0, recipeStart).trim();
        final afterRecipe = message.substring(recipeEnd + 9).trim();
        return {
          'recipe': recipe,
          'beforeRecipe': beforeRecipe,
          'afterRecipe': afterRecipe,
        };
      } catch (e) {
        print("Error decoding recipe JSON: $e");
        return null;
      }
    }
    print(message);
    return {
      'beforeRecipe': message,
      'afterRecipe': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.trim().isEmpty || message == "loading") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: ColorPalette.darkgray,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.more_horiz,
            color: ColorPalette.offWhite,
          ),
        ),
      );
    }

    final recipe = extractRecipe(message!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recipe!['beforeRecipe'].isNotEmpty)
            MessageWidget(
              messageText: recipe['beforeRecipe'],
              isUser: false,
            ),
          if (recipe['recipe'] != null)
            RecipeCard(
              title: recipe['recipe']['title'],
              ingredients: List<Ingredient>.from(recipe['recipe']['ingredients']
                  .map(
                      (ingredientJson) => Ingredient.fromJson(ingredientJson))),
              instructions: List<String>.from(recipe['recipe']['instructions']),
              cookingTime: recipe['recipe']['cooking_time'],
              preparationTime: recipe['recipe']['preparation_time'],
              tags: List<String>.from(recipe['recipe']['tags']),
              description: recipe['recipe']['description'],
              notes: recipe['recipe']['notes'],
            ),
          if (recipe['afterRecipe'].isNotEmpty)
            MessageWidget(
              messageText: recipe['afterRecipe'],
              isUser: false,
            ),
        ],
      ),
    );
  }
}
