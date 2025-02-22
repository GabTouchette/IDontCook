import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile/models/recipe/recipe.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/chatbot/chat_message.dart';
import 'package:mobile/widgets/chatbot/recipe_card.dart';
import 'package:mobile/widgets/chatbot/user_recipe_card.dart';

class AiResponseBubble extends StatelessWidget {
  final String? message;
  final bool isLoading;

  const AiResponseBubble({super.key, this.message, this.isLoading = false});

  List<String> splitRecipes(String message) {
    final regex = RegExp(
        r'(<recipe>.*?</recipe>)|(<userRecipe>.*?</userRecipe>)',
        dotAll: true);
    final matches = regex.allMatches(message);

    List<String> parts = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        parts.add(message.substring(lastIndex, match.start).trim());
      }
      parts.add(match.group(0)!);
      lastIndex = match.end;
    }

    if (lastIndex < message.length) {
      parts.add(message.substring(lastIndex).trim());
    }

    return parts.where((part) => part.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading ||
        message == null ||
        message!.trim().isEmpty ||
        message == "loading") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: ColorPalette.darkgray,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: ColorPalette.offWhite,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    final recipeParts = splitRecipes(message!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recipeParts.map<Widget>((part) {
          Widget widget;
          if (part.startsWith("<recipe>") && part.endsWith("</recipe>")) {
            final recipeJson = json.decode(part.substring(8, part.length - 9));
            widget = RecipeCard(
              recipe: Recipe.fromJson(recipeJson),
            );
          } else if (part.startsWith("<userRecipe>") &&
              part.endsWith("</userRecipe>")) {
            final userRecipeJson =
                json.decode(part.substring(12, part.length - 13));
            widget = UserRecipeCard(
              recipeId: userRecipeJson['id'],
            );
          } else {
            widget = MessageWidget(
              messageText: part,
              isUser: false,
            );
          }

          return Column(
            children: [
              widget,
              SizedBox(height: 6.0),
            ],
          );
        }).toList(),
      ),
    );
  }
}
