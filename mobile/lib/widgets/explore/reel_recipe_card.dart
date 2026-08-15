import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';
import 'package:i_cant_cook/api/api_config.dart';

const _lime = Color(0xFFCAFF00);

/// Full-bleed, single-card recipe surface for the reel-style Explore feed.
/// One of these fills the viewport per page of the snapping [PageView].
class ReelRecipeCard extends StatefulWidget {
  final RecipePreview recipe;
  final VoidCallback? onThumbsUp;
  final VoidCallback? onThumbsDown;
  final VoidCallback? onDelete;

  const ReelRecipeCard({
    Key? key,
    required this.recipe,
    this.onThumbsUp,
    this.onThumbsDown,
    this.onDelete,
  }) : super(key: key);

  @override
  State<ReelRecipeCard> createState() => _ReelRecipeCardState();
}

class _ReelRecipeCardState extends State<ReelRecipeCard> {
  bool _thumbedUp = false;

  void _showDownvoteSheet(BuildContext context) {
    HapticService.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.recipe.title,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.12),
            ),
            ListTile(
              leading: Icon(Icons.thumb_down_outlined,
                  color: Theme.of(context).colorScheme.onSurface),
              title: Text(
                'Not for me',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Hide from recommendations',
                style: GoogleFonts.spaceGrotesk(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                widget.onThumbsDown?.call();
              },
            ),
            if (widget.onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  'Delete recipe',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(
                  'Permanently remove from database',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onDelete!();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String? _timeText() {
    final parts = <String>[];
    if (widget.recipe.preparation_time != null) {
      parts.add('${widget.recipe.preparation_time}m prep');
    }
    if (widget.recipe.cooking_time != null) {
      parts.add('${widget.recipe.cooking_time}m cook');
    }
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final showFeedback = widget.onThumbsUp != null || widget.onThumbsDown != null;
    final timeText = _timeText();

    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipeId: recipe.id),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed background image
          recipe.thumbnail_url != null && recipe.thumbnail_url!.isNotEmpty
              ? Image.network(
                  ApiConfig.resolveImageUrl(recipe.thumbnail_url!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      PlaceholderImageWidget(recipeId: recipe.id, height: 2000),
                )
              : PlaceholderImageWidget(recipeId: recipe.id, height: 2000),

          // Bottom scrim for text legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.18, 0.45, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                ),
              ),
            ),
          ),

          // Right-hand action rail (TikTok/Reels style)
          if (showFeedback)
            Positioned(
              right: 12,
              bottom: 130,
              child: Column(
                children: [
                  if (widget.onThumbsUp != null)
                    _ActionButton(
                      icon: _thumbedUp ? Icons.favorite : Icons.favorite_border,
                      isActive: _thumbedUp,
                      onTap: () {
                        HapticService.lightImpact();
                        setState(() => _thumbedUp = !_thumbedUp);
                        widget.onThumbsUp!();
                      },
                    ),
                  if (widget.onThumbsDown != null) ...[
                    const SizedBox(height: 20),
                    _ActionButton(
                      icon: Icons.thumb_down_outlined,
                      isActive: false,
                      onTap: () => _showDownvoteSheet(context),
                    ),
                  ],
                ],
              ),
            ),

          // Bottom content
          Positioned(
            left: 20,
            right: showFeedback ? 88 : 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  recipe.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timeText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    timeText,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
                if (recipe.description != null &&
                    recipe.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    recipe.description!,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (recipe.tags != null && recipe.tags!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (int i = 0;
                          i < (recipe.tags!.length > 3 ? 3 : recipe.tags!.length);
                          i++)
                        _tagChip(recipe.tags![i]),
                      if (recipe.tags!.length > 3)
                        _tagChip('+${recipe.tags!.length - 3}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

/// Circular action button used in the right-hand rail.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isActive ? _lime : Colors.white,
        ),
      ),
    );
  }
}
