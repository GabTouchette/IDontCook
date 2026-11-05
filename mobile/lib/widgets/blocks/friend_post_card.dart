import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:i_cant_cook/api/api_config.dart';

/// Renders a `friend_post` module: author avatar (fallback: first letter of
/// username, since `avatar_url` is currently always null server-side),
/// preview text, an optional recipe thumbnail row, and a relative
/// `created_at` time. Tapping the recipe thumbnail (when present) opens the
/// recipe.
class FriendPostCard extends StatelessWidget {
  final FriendPostPayload payload;

  /// The module's human-readable "why you're seeing this" line.
  final String reason;

  const FriendPostCard({
    super.key,
    required this.payload,
    this.reason = '',
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final author = payload.author;
    final timeLabel = relativeTimeLabel(payload.created_at);
    final recipe = payload.recipe;

    return Container(
      padding: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: onSurface.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarFallback(username: author.username),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author.username.isNotEmpty
                          ? author.username
                          : 'Someone',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    if (timeLabel.isNotEmpty)
                      Text(
                        timeLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (payload.preview_text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              payload.preview_text,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: onSurface,
                height: 1.35,
              ),
            ),
          ],
          if (recipe != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RecipeDetailPage(recipeId: recipe.id),
                  ),
                );
              },
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: recipe.image_url != null
                          ? Image.network(
                              ApiConfig.resolveImageUrl(recipe.image_url!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _imagePlaceholder(context),
                            )
                          : _imagePlaceholder(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reasonIcon(reason) != null) ...[
                  Icon(reasonIcon(reason),
                      size: 13, color: onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 5),
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
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
      child: Icon(
        Icons.restaurant_menu,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}

/// Default circular avatar showing the username's first letter, used while
/// `avatar_url` is null (currently always, server-side).
class _AvatarFallback extends StatelessWidget {
  final String username;

  const _AvatarFallback({required this.username});

  @override
  Widget build(BuildContext context) {
    final letter = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kBlockAccent(context),
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: kBlockAccentInk(context),
        ),
      ),
    );
  }
}
