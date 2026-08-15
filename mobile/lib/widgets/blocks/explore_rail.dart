import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/api/api_config.dart';

/// Renders an `explore_rail` module: a titled horizontal list of compact
/// recipe tiles. Tapping a tile opens the recipe.
class ExploreRail extends StatelessWidget {
  final ExploreRailPayload payload;

  const ExploreRail({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    if (payload.recipes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payload.title.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.search,
                  size: 16, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                payload.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: payload.recipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _RailTile(recipe: payload.recipes[index]),
          ),
        ),
      ],
    );
  }
}

class _RailTile extends StatelessWidget {
  final RecipeSummary recipe;

  const _RailTile({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

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
        width: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              width: double.infinity,
              child: recipe.image_url != null
                  ? Image.network(
                      ApiConfig.resolveImageUrl(recipe.image_url!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(context),
                    )
                  : _imagePlaceholder(context),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: onSurface,
                        ),
                      ),
                    ),
                    if (recipe.total_time != null)
                      Text(
                        '${recipe.total_time} min',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.4),
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

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
      child: Icon(
        Icons.restaurant_menu,
        size: 24,
        color:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}
