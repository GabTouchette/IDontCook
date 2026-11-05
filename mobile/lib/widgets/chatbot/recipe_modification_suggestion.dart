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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  recipe.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (recipe.description != null && recipe.description!.isNotEmpty)
                  Text(
                    recipe.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (recipe.preparation_time != null)
                      '${recipe.preparation_time}m prep',
                    if (recipe.cooking_time != null)
                      '${recipe.cooking_time}m cook',
                  ].join('  ·  '),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'INGREDIENTS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 6),
                ...recipe.ingredients.take(3).map((ingredient) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '– ${_formatIngredient(ingredient)}',
                        style: GoogleFonts.spaceGrotesk(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                if (recipe.ingredients.length > 3)
                  Text(
                    '+ ${recipe.ingredients.length - 3} more',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            height: 0,
          ),
          GestureDetector(
            onTap: () => _onPreview(context),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Theme.of(context).colorScheme.secondary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.preview_outlined,
                    color: Theme.of(context).colorScheme.onSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PREVIEW CHANGES',
                    style: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatIngredient(dynamic ingredient) {
    final parts = <String>[];
    final qty = ingredient.quantity;
    if (qty != null && qty > 0) {
      if (qty == qty.truncateToDouble()) {
        parts.add(qty.toInt().toString());
      } else {
        parts.add(qty.toString());
      }
    }
    final unit = ingredient.unit as String?;
    if (unit != null && unit.isNotEmpty) parts.add(unit);
    final name = ingredient.name as String?;
    if (name != null && name.isNotEmpty) parts.add(name);
    return parts.join(' ');
  }
}
