import 'package:flutter/material.dart';
import 'package:i_cant_cook/enums/recipe_view_mode.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/pages/recipe_detail_page/recipe_detail_page.dart';
import 'package:i_cant_cook/providers/recipe_detail_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:provider/provider.dart';

class RecipeModificationSuggestion extends StatelessWidget {
  final Recipe recipe;

  const RecipeModificationSuggestion({super.key, required this.recipe});

  void _onPreview(BuildContext context) {
    final originalRecipe =
        Provider.of<RecipeDetailProvider>(context, listen: false).recipe;

    if (originalRecipe == null) return;

    final updatedFields = <String>{};

    final mergedRecipe = originalRecipe.copyWith(
      title: _track("title", recipe.title, originalRecipe.title, updatedFields),
      ingredients: _track("ingredients", recipe.ingredients,
          originalRecipe.ingredients, updatedFields),
      instructions: _track("instructions", recipe.instructions,
          originalRecipe.instructions, updatedFields),
      preparation_time: _track("preparation_time", recipe.preparation_time,
          originalRecipe.preparation_time, updatedFields),
      cooking_time: _track("cooking_time", recipe.cooking_time,
          originalRecipe.cooking_time, updatedFields),
      description: _track("description", recipe.description,
          originalRecipe.description, updatedFields),
      notes: _track("notes", recipe.notes, originalRecipe.notes, updatedFields),
      tags: _track("tags", recipe.tags, originalRecipe.tags, updatedFields),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailPage(
          recipe: mergedRecipe,
          viewMode: RecipeViewMode.preview(),
          updatedFields: updatedFields,
        ),
      ),
    );
  }

  T _track<T>(String key, T? newValue, T oldValue, Set<String> updatedFields) {
    if (newValue != null && newValue != oldValue) {
      updatedFields.add(key);
      return newValue;
    }
    return oldValue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      color: ColorPalette.darkgray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.offWhite,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                if (recipe.description != null &&
                    recipe.description!.isNotEmpty)
                  Text(
                    recipe.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 8),
                // Time info
                Row(
                  children: [
                    const Icon(Icons.timer,
                        color: ColorPalette.offWhite, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      "${recipe.preparation_time} min",
                      style: const TextStyle(color: ColorPalette.offWhite),
                    ),
                    const SizedBox(width: 15),
                    const Icon(Icons.local_fire_department,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      "${recipe.cooking_time} min",
                      style: const TextStyle(color: ColorPalette.offWhite),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Ingredients",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.offWhite,
                  ),
                ),
                const SizedBox(height: 5),
                Stack(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxHeight: 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: recipe.ingredients
                            .take(3)
                            .map((ingredient) => Text(
                                  "- ${ingredient.quantity} ${ingredient.name}",
                                  style: const TextStyle(
                                      color: ColorPalette.offWhite),
                                  overflow: TextOverflow.ellipsis,
                                ))
                            .toList(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorPalette.darkgray.withOpacity(0),
                              ColorPalette.darkgray.withOpacity(1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: ColorPalette.placeholdergray, height: 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _textAction("Preview", onTap: () => _onPreview(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textAction(String text, {required VoidCallback onTap}) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: ColorPalette.offWhite,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
