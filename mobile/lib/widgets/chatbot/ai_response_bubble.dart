import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/chatbot/parts/animated_loading_text.dart';
import 'package:i_cant_cook/widgets/chatbot/parts/recipe_parser.dart';
import 'package:i_cant_cook/widgets/chatbot/parts/recipe_part_widget.dart';

class AiResponseBubble extends StatelessWidget {
  final String? message;
  final bool isLoading;
  final bool isRecipeLoading;
  final Recipe? originalRecipe;

  const AiResponseBubble({
    super.key,
    this.message,
    this.isLoading = false,
    this.isRecipeLoading = false,
    this.originalRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _loadingIndicator();
    }

    if (isRecipeLoading) {
      return _animatedTextLoader();
    }

    final recipeParts = RecipeParser.split(message!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recipeParts.map((part) {
        return Column(
          children: [
            RecipePartWidget(part: part, originalRecipe: originalRecipe),
            const SizedBox(height: 6),
          ],
        );
      }).toList(),
    );
  }

  Widget _loadingIndicator() => Container(
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
      );

  Widget _animatedTextLoader() => Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: ColorPalette.darkgray,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [AnimatedLoadingText()],
        ),
      );
}
