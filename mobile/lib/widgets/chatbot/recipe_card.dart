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
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            recipe.description != null
                ? Text(
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
                  )
                : const SizedBox.shrink(),
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
                    '– ${_formatIngredientText(ingredient)}',
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
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailPage(
                      recipe: Recipe(
                        id: -1,
                        image_url: recipe.image_url,
                        title: recipe.title,
                        preparation_time: recipe.preparation_time,
                        cooking_time: recipe.cooking_time,
                        servings: recipe.servings,
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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                color: Theme.of(context).colorScheme.secondary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_rounded,
                        color: Theme.of(context).colorScheme.onSecondary,
                        size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'FULL RECIPE',
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
      ),
    );
  }

  String _formatIngredientText(Ingredient ingredient) {
    final parts = <String>[];
    if (ingredient.quantity != null && ingredient.quantity! > 0) {
      if (ingredient.quantity! == ingredient.quantity!.truncateToDouble()) {
        parts.add(ingredient.quantity!.toInt().toString());
      } else {
        parts.add(ingredient.quantity!.toString());
      }
    }
    if (ingredient.unit != null && ingredient.unit!.isNotEmpty) {
      parts.add(ingredient.unit!);
    }
    parts.add(ingredient.name ?? '');
    return parts.join(' ');
  }
}
