import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';

/// Renders a `recipe_ref` block: a compact tappable row that opens the
/// referenced recipe in [RecipeDetailPage] (same behavior as the v1 `&&`
/// delimiter handling, but without a network round-trip for the title).
class RecipeRefRow extends StatelessWidget {
  final RecipeSummary recipe;

  const RecipeRefRow({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final metaParts = <String>[
      if (recipe.total_time != null) '${recipe.total_time} min',
      if (recipe.calories != null) '${recipe.calories} cal',
    ];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipeId: recipe.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        decoration: blockCardDecoration(context),
        child: Row(
          children: [
            if (recipe.image_url != null) ...[
              SizedBox(
                width: 44,
                height: 44,
                child: Image.network(
                  recipe.image_url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.06),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (metaParts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      metaParts.join('  ·  '),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 34,
              height: 34,
              color: kBlockAccent,
              child: const Icon(
                Icons.restaurant_menu,
                color: kBlockAccentInk,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
