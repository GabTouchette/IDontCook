import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
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

  Widget _loadingIndicator() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _animatedTextLoader() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [AnimatedLoadingText()],
        ),
      ),
    );
  }
}
