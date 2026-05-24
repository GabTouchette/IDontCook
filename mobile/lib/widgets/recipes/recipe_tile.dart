import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/enums/recipe_view_mode.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/providers/user_recipes_provider.dart';
import 'package:i_cant_cook/widgets/dialogs/recipe_preview_dialog.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:provider/provider.dart';

class RecipeTile extends StatelessWidget {
  final RecipePreview recipe;
  final bool large;
  final bool medium;
  final bool small;
  final RecipeViewMode viewMode;

  const RecipeTile({
    Key? key,
    required this.recipe,
    this.large = false,
    this.medium = false,
    this.small = false,
    this.viewMode = const RecipeViewMode.normal(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (small) return _buildSmallTile(context);
    if (large) return _buildLargeTile(context);
    return _buildMediumTile(context);
  }

  // ─── SMALL (list mode) ────────────────────────────────────────────────────
  Widget _buildSmallTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetailPage(context),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: GoogleFonts.spaceGrotesk(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildTimeText(context, fontSize: 12),
                    ],
                  ),
                ),
                if (recipe.is_favorite ?? false)
                  Icon(Icons.favorite,
                      size: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4)),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color:
                Theme.of(context).colorScheme.outline.withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  // ─── MEDIUM (default) ─────────────────────────────────────────────────────
  Widget _buildMediumTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetailPage(context),
      onLongPress: () => _showPreview(context),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Square thumbnail — ClipRect contains placeholder BackdropFilter
                ClipRect(child: _squareImage(recipe.thumbnail_url, 80)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: GoogleFonts.spaceGrotesk(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _buildTimeText(context, fontSize: 12),
                      if (recipe.ingredients_count != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${recipe.ingredients_count} ingredients',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.35),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (recipe.is_favorite ?? false)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Icon(Icons.favorite,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.35)),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color:
                Theme.of(context).colorScheme.outline.withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  // ─── LARGE (card mode) ────────────────────────────────────────────────────
  Widget _buildLargeTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetailPage(context),
      onLongPress: () => _showPreview(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-bleed image — ClipRect contains placeholder BackdropFilter
          ClipRect(
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: recipe.thumbnail_url != null &&
                      recipe.thumbnail_url!.isNotEmpty
                  ? Image.network(
                      recipe.thumbnail_url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => PlaceholderImageWidget(
                          recipeId: recipe.id, height: 200),
                    )
                  : PlaceholderImageWidget(recipeId: recipe.id, height: 200),
            ),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Stats row
                Row(
                  children: [
                    _buildTimeText(context, fontSize: 12),
                    if (recipe.ingredients_count != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${recipe.ingredients_count} ITEMS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.35),
                        ),
                      ),
                    ],
                    if (recipe.is_favorite ?? false) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.favorite,
                          size: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.35)),
                    ],
                  ],
                ),
                // Tags
                if (recipe.tags != null && recipe.tags!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (int i = 0;
                          i < (recipe.tags!.length > 4 ? 4 : recipe.tags!.length);
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

  // ─── Shared helpers ───────────────────────────────────────────────────────
  Widget _buildTimeText(BuildContext context, {double fontSize = 12}) {
    final parts = <String>[];
    if (recipe.preparation_time != null)
      parts.add('${recipe.preparation_time}m prep');
    if (recipe.cooking_time != null) parts.add('${recipe.cooking_time}m cook');
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join('  ·  '),
      style: GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }

  Widget _squareImage(String? imageUrl, int size) {
    return SizedBox(
      width: size.toDouble(),
      height: size.toDouble(),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  PlaceholderImageWidget(recipeId: recipe.id, height: size),
            )
          : PlaceholderImageWidget(recipeId: recipe.id, height: size),
    );
  }

  Widget _tagChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
        ),
      ),
    );
  }

  void _openDetailPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecipeDetailPage(recipeId: recipe.id, viewMode: viewMode),
      ),
    ).then((_) {
      final recipesProvider =
          Provider.of<UserRecipesProvider>(context, listen: false);
      recipesProvider.fetchRecipes();
      recipesProvider.setTabIndex(0);
    });
  }

  void _showPreview(BuildContext context) async {
    try {
      var res = await RecipeApi().getRecipeById(recipe.id);
      var fullRecipe = Recipe.fromJson(res);
      showDialog(
        context: context,
        barrierColor: Colors.black45,
        builder: (_) => RecipePreviewDialog(recipe: fullRecipe),
      );
    } catch (e) {
      InformationToast.show(
        context: context,
        message: 'Could not load preview',
        type: ToastType.error,
      );
    }
  }
}
