import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/pages/recipe_detail_page/recipe_detail_page.dart';
import 'package:i_cant_cook/providers/recipes_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/dialogs/recipe_preview_dialog.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';
import 'package:provider/provider.dart';

class RecipeTile extends StatelessWidget {
  final RecipePreview recipe;
  final bool large;
  final bool medium;
  final bool small;

  const RecipeTile({
    Key? key,
    required this.recipe,
    this.large = false,
    this.medium = false,
    this.small = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (small) {
      return _buildSmallTile(context);
    } else if (large) {
      return _buildLargeTile(context);
    } else {
      return _buildMediumTile(context);
    }
  }

  Widget _buildSmallTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetailPage(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: ColorPalette.lightgray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe.title,
              style: const TextStyle(
                color: ColorPalette.offBlack,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _buildTimeRow(iconSize: 14, fontSize: 13),
          ],
        ),
      ),
    );
  }

  Widget _buildMediumTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetailPage(context),
      onLongPress: () => _showPreview(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: ColorPalette.lightgray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            getSmallRecipeImage(recipe.thumbnail_url),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      color: ColorPalette.offBlack,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6.0),
                  _buildTimeRow(iconSize: 16, fontSize: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetailPage(context),
      onLongPress: () => _showPreview(context),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: ColorPalette.lightgray,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: recipe.thumbnail_url != null &&
                        recipe.thumbnail_url!.isNotEmpty
                    ? Image.network(
                        recipe.thumbnail_url!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : PlaceholderImageWidget(recipeId: recipe.id, height: 200),
              ),
              const SizedBox(height: 12),
              Text(
                recipe.title,
                style: const TextStyle(
                  color: ColorPalette.offBlack,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildTimeRow(iconSize: 18, fontSize: 15),
              const SizedBox(height: 8),
              Text(
                '${'N/A'} ingredients',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorPalette.offBlack,
                ),
              ),
              const SizedBox(height: 8),
              if (recipe.tags != null && recipe.tags!.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    for (int i = 0;
                        i < (recipe.tags!.length > 5 ? 5 : recipe.tags!.length);
                        i++)
                      _buildTagChip(recipe.tags![i]),
                    if (recipe.tags!.length > 5)
                      _buildTagChip('+ ${recipe.tags!.length - 5} others'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow({double iconSize = 16, double fontSize = 14}) {
    return Row(
      children: [
        if (recipe.preparation_time != null) ...[
          Icon(Icons.timer, size: iconSize, color: ColorPalette.green),
          const SizedBox(width: 4),
          Text(
            '${recipe.preparation_time} min',
            style: TextStyle(fontSize: fontSize, color: ColorPalette.offBlack),
          ),
        ],
        if (recipe.preparation_time != null && recipe.cooking_time != null)
          const SizedBox(width: 12),
        if (recipe.cooking_time != null) ...[
          Icon(Icons.local_fire_department,
              size: iconSize, color: ColorPalette.red),
          const SizedBox(width: 4),
          Text(
            '${recipe.cooking_time} min',
            style: TextStyle(fontSize: fontSize, color: ColorPalette.offBlack),
          ),
        ],
        const SizedBox(width: 12),
        if (recipe.is_favorite ?? false) ...[
          Icon(Icons.favorite,
              size: iconSize,
              color: Colors.redAccent.withOpacity(0.85)), // or ColorPalette.red
        ],
      ],
    );
  }

  void _openDetailPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(recipeId: recipe.id),
      ),
    ).then((_) {
      final recipesProvider =
          Provider.of<RecipesProvider>(context, listen: false);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load preview')),
      );
    }
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: ColorPalette.darkgray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget getSmallRecipeImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            )
          : PlaceholderImageWidget(recipeId: recipe.id, height: 100),
    );
  }
}
