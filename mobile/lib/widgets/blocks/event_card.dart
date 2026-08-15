import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/home_module/home_module.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:i_cant_cook/api/api_config.dart';

/// Renders an `event_card` module: an ephemeral, festive card — lime accent
/// border and a title badge, body text, optional image, optional CTA, and an
/// optional horizontal mini-rail of the event's recipes. Tapping the CTA
/// calls [onCtaTap] with the owning [module]
/// (`BlockCallbacks.onModuleCtaTap`); tapping a rail recipe opens it.
class EventCard extends StatelessWidget {
  final HomeModule module;
  final void Function(HomeModule module)? onCtaTap;

  const EventCard({
    super.key,
    required this.module,
    this.onCtaTap,
  });

  EventCardPayload get payload => module.payload as EventCardPayload;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final title = payload.title.isNotEmpty ? payload.title : 'Happening now';

    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          kBlockAccent.withValues(alpha: 0.06),
          Theme.of(context).colorScheme.surface,
        ),
        border: Border.all(color: kBlockAccent, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (payload.image_url != null)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.network(
                ApiConfig.resolveImageUrl(payload.image_url!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 10.0),
                  color: kBlockAccent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.celebration_outlined,
                          size: 13, color: kBlockAccentInk),
                      const SizedBox(width: 6),
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: kBlockAccentInk,
                        ),
                      ),
                    ],
                  ),
                ),
                if (payload.body.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    payload.body,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: onSurface,
                      height: 1.35,
                    ),
                  ),
                ],
                if (payload.recipes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: payload.recipes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) =>
                          _EventRailTile(recipe: payload.recipes[index]),
                    ),
                  ),
                ],
                if (payload.cta != null && payload.cta!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => onCtaTap?.call(module),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: kBlockAccent, width: 1.5),
                      ),
                      child: Text(
                        payload.cta!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRailTile extends StatelessWidget {
  final RecipeSummary recipe;

  const _EventRailTile({required this.recipe});

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
        width: 120,
        decoration: blockCardDecoration(context, outlineOpacity: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 84,
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                recipe.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: onSurface,
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
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}
