import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';
import 'package:i_cant_cook/api/api_config.dart';

/// Renders a `hero_suggestion` module — the "main character" of the feed.
/// When an image is available it goes full-bleed behind a dark gradient
/// scrim, with title/tagline/reason/chips overlaid at the bottom for
/// maximum visual weight; without one (or if it fails to load) it falls
/// back to the same [PlaceholderImageWidget] used on the recipe detail
/// page, so a missing image reads identically everywhere in the app.
/// Tapping opens the recipe.
class HeroSuggestionCard extends StatelessWidget {
  final HeroSuggestionPayload payload;

  /// The module's human-readable "why you're seeing this" line.
  final String reason;

  /// Height of the image/placeholder area. Shorter than a typical detail
  /// page hero image, since this card also carries title/tagline/chips.
  static const double _imageHeight = 170.0;

  const HeroSuggestionCard({
    super.key,
    required this.payload,
    this.reason = '',
  });

  @override
  Widget build(BuildContext context) {
    final recipe = payload.recipe;
    final hasImage = recipe.image_url != null;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // White-on-image when there's a scrim to sit on top of; onSurface
    // otherwise (fallback placeholder is its own dark/warm-grey tone).
    final titleColor = hasImage ? Colors.white : onSurface;
    final mutedColor =
        hasImage ? Colors.white.withValues(alpha: 0.75) : onSurface.withValues(alpha: 0.5);
    final icon = reasonIcon(reason);

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
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        child: Stack(
          children: [
            if (hasImage)
              Positioned.fill(
                child: Image.network(
                  ApiConfig.resolveImageUrl(recipe.image_url!),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return PlaceholderImageWidget(
                      recipeId: recipe.id,
                      height: _imageHeight.toInt(),
                    );
                  },
                  errorBuilder: (_, __, ___) => PlaceholderImageWidget(
                    recipeId: recipe.id,
                    height: _imageHeight.toInt(),
                  ),
                ),
              )
            else
              PlaceholderImageWidget(
                recipeId: recipe.id,
                height: _imageHeight.toInt(),
              ),
            if (hasImage)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.45, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: hasImage ? _imageHeight : 0),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (payload.tagline.isNotEmpty) ...[
                        Text(
                          payload.tagline.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: mutedColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        recipe.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 14, color: mutedColor),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                reason,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: reasonTextStyle(context, color: mutedColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (recipe.total_time != null ||
                          recipe.calories != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (recipe.total_time != null) ...[
                              _InfoChip(
                                icon: Icons.schedule,
                                label: '${recipe.total_time} min',
                                onImage: hasImage,
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (recipe.calories != null)
                              _InfoChip(
                                icon: Icons.local_fire_department_outlined,
                                label: '${recipe.calories} cal',
                                onImage: hasImage,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool onImage;

  const _InfoChip({required this.icon, required this.label, required this.onImage});

  @override
  Widget build(BuildContext context) {
    final fg = onImage ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: onImage ? Colors.white.withValues(alpha: 0.14) : null,
        borderRadius: BorderRadius.circular(999),
        border: onImage
            ? null
            : Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: 1.5,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg.withValues(alpha: onImage ? 0.9 : 0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
