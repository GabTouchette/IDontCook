import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/pages/recipe_detail_page/recipe_detail_page.dart';
import 'package:i_cant_cook/providers/recipes_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';
import 'package:provider/provider.dart';

class RecipeTile extends StatelessWidget {
  final RecipePreview recipe;

  const RecipeTile({
    Key? key,
    required this.recipe,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: ColorPalette.lightgray,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            fontWeight: FontWeight.w300,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            if (recipe.preparation_time != null) ...[
                              const Icon(Icons.timer,
                                  size: 16, color: ColorPalette.offBlack),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.preparation_time} min',
                                style: TextStyle(color: ColorPalette.offBlack),
                              ),
                            ],
                            if (recipe.preparation_time != null &&
                                recipe.cooking_time != null)
                              const SizedBox(width: 12),
                            if (recipe.cooking_time != null) ...[
                              const Icon(Icons.local_fire_department,
                                  size: 16, color: ColorPalette.offBlack),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.cooking_time} min',
                                style: TextStyle(color: ColorPalette.offBlack),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              if (recipe.tags != null && recipe.tags!.isNotEmpty) ...[
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: recipe.tags!.map((tag) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: ColorPalette.darkgray,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 6.0),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
