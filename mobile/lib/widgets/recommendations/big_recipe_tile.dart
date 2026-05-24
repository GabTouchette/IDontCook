import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';

class BigRecipeTile extends StatelessWidget {
  final RecipePreview recipe;

  const BigRecipeTile({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipeId: recipe.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-bleed image
          SizedBox(
            height: 220,
            width: double.infinity,
            child: recipe.thumbnail_url != null &&
                    recipe.thumbnail_url!.isNotEmpty
                ? Image.network(
                    recipe.thumbnail_url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        PlaceholderImageWidget(recipeId: recipe.id, height: 220),
                  )
                : PlaceholderImageWidget(recipeId: recipe.id, height: 220),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Time row
                _buildTimeText(context),
                // Description
                if (recipe.description != null &&
                    recipe.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    recipe.description!,
                    style: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Tags
                if (recipe.tags != null && recipe.tags!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (int i = 0;
                          i <
                              (recipe.tags!.length > 4
                                  ? 4
                                  : recipe.tags!.length);
                          i++)
                        _tagChip(context, recipe.tags![i]),
                      if (recipe.tags!.length > 4)
                        _tagChip(context, '+${recipe.tags!.length - 4}'),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.10),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeText(BuildContext context) {
    final parts = <String>[];
    if (recipe.preparation_time != null)
      parts.add('${recipe.preparation_time}m prep');
    if (recipe.cooking_time != null) parts.add('${recipe.cooking_time}m cook');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join('  ·  '),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }

  Widget _tagChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.45),
          width: 1.5,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
        ),
      ),
    );
  }
}

