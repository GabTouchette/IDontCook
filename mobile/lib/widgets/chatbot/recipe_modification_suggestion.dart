import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/enums/recipe_view_mode.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/providers/recipe_detail_provider.dart';
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
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
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
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
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
                    style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                // Time info
                Row(
                  children: [
                    Icon(Icons.timer,
                        color: Theme.of(context).colorScheme.primary, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      "${recipe.preparation_time} min",
                      style: GoogleFonts.nunito(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Icon(Icons.local_fire_department,
                        color: Theme.of(context).colorScheme.error, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      "${recipe.cooking_time} min",
                      style: GoogleFonts.nunito(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Ingredients",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Stack(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxHeight: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: recipe.ingredients
                            .take(3)
                            .map((ingredient) => Text(
                                  "- ${ingredient.quantity} ${ingredient.unit} ${ingredient.name}",
                                  style: GoogleFonts.nunito(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ))
                            .toList(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0),
                              Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(1),
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
          Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            height: 0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _textAction("Preview", context, onTap: () => _onPreview(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textAction(String text, BuildContext context,
      {required VoidCallback onTap}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.nunito(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
