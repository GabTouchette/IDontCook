import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/models/ingredient/ingredient.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({
    super.key,
    required this.recipe,
  });

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 130),
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
              ],
            ),
            const SizedBox(height: 8),
            recipe.description != null
                ? Text(
                    recipe.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 8),
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
                const Spacer(),
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
                              "- ${_formatIngredientText(ingredient)}",
                              style: GoogleFonts.nunito(
                                color: Theme.of(context).colorScheme.onSurface,
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
                  height: 90,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface.withOpacity(0),
                          Theme.of(context).colorScheme.surface.withOpacity(1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Column(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailPage(
                              recipe: Recipe(
                                id: -1,
                                image_url: "",
                                title: recipe.title,
                                preparation_time: recipe.preparation_time,
                                cooking_time: recipe.cooking_time,
                                ingredients: recipe.ingredients,
                                instructions: recipe.instructions,
                                description: recipe.description,
                                notes: recipe.notes,
                                tags: recipe.tags,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.menu_book_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      label: Text(
                        "Full recipe",
                        style: GoogleFonts.nunito(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatIngredientText(Ingredient ingredient) {
    final parts = <String>[];

    // Add quantity if available
    if (ingredient.quantity != null && ingredient.quantity! > 0) {
      // Format quantity to avoid unnecessary decimals
      if (ingredient.quantity! == ingredient.quantity!.truncateToDouble()) {
        parts.add(ingredient.quantity!.toInt().toString());
      } else {
        parts.add(ingredient.quantity!.toString());
      }
    }

    // Add unit if available
    if (ingredient.unit != null && ingredient.unit!.isNotEmpty) {
      parts.add(ingredient.unit!);
    }

    // Add name
    if (ingredient.name != null && ingredient.name!.isNotEmpty) {
      parts.add(ingredient.name!);
    }

    return parts.isNotEmpty ? parts.join(' ') : 'Unknown ingredient';
  }
}
