import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/theme.dart';

class RecipePreviewDialog extends StatelessWidget {
  final Recipe recipe;

  const RecipePreviewDialog({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.backgroundLight,
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 500),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.backgroundDark)),
                  const SizedBox(height: 12),
                  if (recipe.description != null &&
                      recipe.description!.trim().isNotEmpty)
                    Text(
                      recipe.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 12),
                  if (recipe.ingredients.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingredients:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ...recipe.ingredients
                            .take(6)
                            .map((i) => Text('- ${i.name}'))
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
