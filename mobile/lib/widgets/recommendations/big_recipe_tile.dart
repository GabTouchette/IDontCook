import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';
import 'package:i_cant_cook/api/api_config.dart';

class BigRecipeTile extends StatefulWidget {
  final RecipePreview recipe;
  final VoidCallback? onThumbsUp;
  final VoidCallback? onThumbsDown;
  final VoidCallback? onDelete;

  const BigRecipeTile({
    Key? key,
    required this.recipe,
    this.onThumbsUp,
    this.onThumbsDown,
    this.onDelete,
  }) : super(key: key);

  @override
  State<BigRecipeTile> createState() => _BigRecipeTileState();
}

class _BigRecipeTileState extends State<BigRecipeTile> {
  bool _pressed = false;
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

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final showFeedback = widget.onThumbsUp != null || widget.onThumbsDown != null;

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
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-bleed image with optional feedback buttons
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: recipe.thumbnail_url != null &&
                          recipe.thumbnail_url!.isNotEmpty
                      ? Image.network(
                          ApiConfig.resolveImageUrl(recipe.thumbnail_url!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              PlaceholderImageWidget(
                                  recipeId: recipe.id, height: 220),
                        )
                      : PlaceholderImageWidget(
                          recipeId: recipe.id, height: 220),
                ),
                if (showFeedback)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        if (widget.onThumbsUp != null)
                          _FeedbackButton(
                            icon: Icons.thumb_up,
                            isActive: _thumbedUp,
                            onTap: () {
                              HapticService.lightImpact();
                              setState(() => _thumbedUp = !_thumbedUp);
                              widget.onThumbsUp!();
                            },
                          ),
                        if (widget.onThumbsDown != null) ...[
                          const SizedBox(width: 6),
                          _FeedbackButton(
                            icon: Icons.thumb_down,
                            isActive: false,
                            onTap: () => _showDownvoteSheet(context),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
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
                  _buildTimeText(context),
                  if (recipe.description != null &&
                      recipe.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      recipe.description!,
                      style: GoogleFonts.spaceGrotesk(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeText(BuildContext context) {
    final parts = <String>[];
    if (widget.recipe.preparation_time != null)
      parts.add('${widget.recipe.preparation_time}m prep');
    if (widget.recipe.cooking_time != null)
      parts.add('${widget.recipe.cooking_time}m cook');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join('  ·  '),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.4),
      ),
    );
  }

  Widget _tagChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

/// Small square feedback button overlaid on the recipe image.
class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FeedbackButton({
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
        width: 36,
        height: 36,
        color: Colors.black.withValues(alpha: 0.55),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Theme.of(context).colorScheme.secondary : Colors.white,
        ),
      ),
    );
  }
}

