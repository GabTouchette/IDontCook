import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:i_cant_cook/theme/theme.dart';
import 'package:i_cant_cook/widgets/chatbot/parts/markdown_style.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/providers/recipe_detail_provider.dart';
import 'package:i_cant_cook/widgets/chatbot/recipe_card.dart';
import 'package:i_cant_cook/widgets/chatbot/user_recipe_card.dart';
import 'package:i_cant_cook/widgets/chatbot/recipe_modification_suggestion.dart';

class RecipePartWidget extends StatelessWidget {
  final String part;
  final Recipe? originalRecipe;

  const RecipePartWidget({
    super.key,
    required this.part,
    this.originalRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (part.startsWith("\$\$") && part.endsWith("\$\$")) {
      try {
        final recipeJson = json.decode(part.substring(2, part.length - 2));
        return RecipeCard(recipe: Recipe.fromJson(recipeJson));
      } catch (_) {
        return _buildError(context, "Failed to decode new recipe.");
      }
    } else if (part.startsWith("&&") && part.endsWith("&&")) {
      try {
        final userRecipeJson = json.decode(part.substring(2, part.length - 2));
        return UserRecipeCard(recipeId: userRecipeJson['id']);
      } catch (_) {
        return _buildError(context, "Failed to decode existing recipe.");
      }
    } else if (part.startsWith("@@") && part.endsWith("@@")) {
      return Consumer<RecipeDetailProvider>(
        builder: (_, provider, __) {
          final recipe = provider.recipe;
          if (recipe == null) return const SizedBox.shrink();
          try {
            final modJson = json.decode(part.substring(2, part.length - 2));
            final modified = Recipe.fromJson(modJson);
            final filled = modified.copyWith(
              title: modified.title.isEmpty ? recipe.title : modified.title,
              ingredients: modified.ingredients.isEmpty
                  ? recipe.ingredients
                  : modified.ingredients,
              instructions: modified.instructions.isEmpty
                  ? recipe.instructions
                  : modified.instructions,
              preparation_time: (modified.preparation_time == null ||
                      modified.preparation_time == 0)
                  ? recipe.preparation_time
                  : modified.preparation_time,
              cooking_time:
                  (modified.cooking_time == null || modified.cooking_time == 0)
                      ? recipe.cooking_time
                      : modified.cooking_time,
              description: (modified.description?.isEmpty ?? true)
                  ? recipe.description
                  : modified.description,
              notes: (modified.notes?.isEmpty ?? true)
                  ? recipe.notes
                  : modified.notes,
              tags: (modified.tags?.isEmpty ?? true)
                  ? recipe.tags
                  : modified.tags,
            );
            return RecipeModificationSuggestion(recipe: filled);
          } catch (_) {
            return _buildError(
                context, "Failed to decode recipe modification.");
          }
        },
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: MarkdownBody(
          data: part,
          styleSheet: markdownStyle,
        ),
      );
    }
  }

  Widget _buildError(BuildContext context, String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.borderMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(msg,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
}
