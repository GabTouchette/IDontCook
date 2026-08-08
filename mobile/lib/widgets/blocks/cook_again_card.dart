import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';

/// Renders a `cook_again` module: recipe image/title, "saved X ago" line
/// derived from `saved_at`, and the module's "why you're seeing this"
/// reason line. Tapping opens the recipe.
class CookAgainCard extends StatelessWidget {
  final CookAgainPayload payload;

  /// The module's human-readable "why you're seeing this" line.
  final String reason;

  const CookAgainCard({
    super.key,
    required this.payload,
    this.reason = '',
  });

  @override
  Widget build(BuildContext context) {
    final recipe = payload.recipe;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final savedLabel = relativeTimeLabel(payload.saved_at);

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
        padding: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: onSurface.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: recipe.image_url != null
                    ? Image.network(
                        recipe.image_url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(context),
                      )
                    : _imagePlaceholder(context),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (savedLabel.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.autorenew,
                              size: 12, color: onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(
                            'SAVED $savedLabel'.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                        height: 1.15,
                      ),
                    ),
                    if (reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reasonIcon(reason) != null) ...[
                            Icon(reasonIcon(reason),
                                size: 12, color: onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              reason,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: reasonTextStyle(context),
                            ),
                          ),
                        ],
                      ),
                    ],
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
        size: 22,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}
