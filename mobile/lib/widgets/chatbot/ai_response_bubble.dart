import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/providers/recipe_detail_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/chatbot/chat_message.dart';
import 'package:i_cant_cook/widgets/chatbot/recipe_card.dart';
import 'package:i_cant_cook/widgets/chatbot/recipe_modification_suggestion.dart';
import 'package:i_cant_cook/widgets/chatbot/user_recipe_card.dart';
import 'package:provider/provider.dart';

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

  List<String> splitRecipes(String message) {
    final regex = RegExp(r'\*\*(.*?)\*\*|&&(.*?)&&|@@(.*?)@@', dotAll: true);
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
    if (isLoading) {
      return Container(
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
    }

    if (isRecipeLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: ColorPalette.darkgray,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedLoadingText(),
          ],
        ),
      );
    }

    final recipeParts = splitRecipes(message!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recipeParts.map<Widget>((part) {
        Widget widget;
        if (part.startsWith("**") && part.endsWith("**")) {
          // New Recipe Suggestion
          try {
            final recipeJson = json.decode(part.substring(2, part.length - 2));
            widget = RecipeCard(
              recipe: Recipe.fromJson(recipeJson),
            );
          } catch (e) {
            widget = _buildErrorWidget(
                "Failed to decode new recipe, please try again.");
          }
        } else if (part.startsWith("&&") && part.endsWith("&&")) {
          // Existing User Recipe Suggestion
          try {
            final userRecipeJson =
                json.decode(part.substring(2, part.length - 2));
            widget = UserRecipeCard(
              recipeId: userRecipeJson['id'],
            );
          } catch (e) {
            widget = _buildErrorWidget(
                "Failed to decode existing recipe, please try again.");
          }
        } else if (part.startsWith("@@") && part.endsWith("@@")) {
          try {
            widget = Consumer<RecipeDetailProvider>(
              builder: (context, provider, _) {
                final originalRecipe = provider.recipe;

                if (originalRecipe == null) {
                  return const SizedBox.shrink(); // Or a loading widget
                }

                try {
                  final modJson =
                      json.decode(part.substring(2, part.length - 2));
                  final modifiedRecipe = Recipe.fromJson(modJson);
                  final filledModRecipe = modifiedRecipe.copyWith(
                    title: modifiedRecipe.title.isEmpty
                        ? originalRecipe.title
                        : modifiedRecipe.title,
                    ingredients: modifiedRecipe.ingredients.isEmpty
                        ? originalRecipe.ingredients
                        : modifiedRecipe.ingredients,
                    instructions: modifiedRecipe.instructions.isEmpty
                        ? originalRecipe.instructions
                        : modifiedRecipe.instructions,
                    preparation_time:
                        (modifiedRecipe.preparation_time == null ||
                                modifiedRecipe.preparation_time == 0)
                            ? originalRecipe.preparation_time
                            : modifiedRecipe.preparation_time,
                    cooking_time: (modifiedRecipe.cooking_time == null ||
                            modifiedRecipe.cooking_time == 0)
                        ? originalRecipe.cooking_time
                        : modifiedRecipe.cooking_time,
                    description: (modifiedRecipe.description?.isEmpty ?? true)
                        ? originalRecipe.description
                        : modifiedRecipe.description,
                    notes: (modifiedRecipe.notes?.isEmpty ?? true)
                        ? originalRecipe.notes
                        : modifiedRecipe.notes,
                    tags: (modifiedRecipe.tags?.isEmpty ?? true)
                        ? originalRecipe.tags
                        : modifiedRecipe.tags,
                  );

                  return RecipeModificationSuggestion(recipe: filledModRecipe);
                } catch (e) {
                  return _buildErrorWidget(
                      "Failed to decode recipe modification.");
                }
              },
            );
          } catch (e) {
            widget = _buildErrorWidget(
                "Failed to decode recipe modification, please try again.");
          }
        } else {
          widget = MessageWidget(
            messageText: part,
            isUser: false,
          );
        }

        return Column(
          children: [
            widget,
            const SizedBox(height: 6.0),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: ColorPalette.darkgray,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        errorMessage,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _AnimatedLoadingText extends StatefulWidget {
  @override
  _AnimatedLoadingTextState createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText>
    with SingleTickerProviderStateMixin {
  int _loadingDots = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _loadingDots = (_loadingDots + 1) % 4;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String loadingText = "Generating recipe" + "." * _loadingDots;
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Text(
              loadingText,
              style: TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        });
  }
}
