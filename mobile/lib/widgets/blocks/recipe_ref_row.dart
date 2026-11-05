import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:i_cant_cook/api/api_config.dart';

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
                  ApiConfig.resolveImageUrl(recipe.image_url!),
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
                  const SizedBox(height: 4),
                  _SourceBadge(isOwned: recipe.is_owned),
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
              color: kBlockAccent(context),
              child: Icon(
                Icons.restaurant_menu,
                color: kBlockAccentInk(context),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact provenance badge on a recipe card — distinguishes one of the
/// user's own saved/created recipes ("Your recipe") from a catalog find
/// ("From cookbook"), so a suggestion's source is legible at a glance.
class _SourceBadge extends StatelessWidget {
  final bool isOwned;

  const _SourceBadge({required this.isOwned});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final color = isOwned ? const Color(0xFF22C55E) : onSurface.withValues(alpha: 0.5);
    final label = isOwned ? 'Your recipe' : 'From cookbook';
    final icon = isOwned ? Icons.bookmark : Icons.menu_book_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
