import 'package:flutter/material.dart';
import 'package:mobile/models/recipe_preview/recipe_preview.dart';
import 'package:mobile/pages/recipe_detail_page.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/recipes/placeholder_image.dart';

class BigRecipeTile extends StatelessWidget {
  final RecipePreview recipe;

  const BigRecipeTile({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  Widget getBigRecipeImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : PlaceholderImageWidget(recipeId: recipe.id, height: 160),
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
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: ColorPalette.lightgray,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big Title
              Text(
                recipe.title,
                style: const TextStyle(
                  color: ColorPalette.offBlack,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12.0),

              // Image and Description Row
              Row(
                children: [
                  Expanded(
                    child: getBigRecipeImage(recipe.image_url),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      recipe.description ?? 'No description available.',
                      style: const TextStyle(
                        color: ColorPalette.offBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Cook and Preparation Time
              Row(
                children: [
                  if (recipe.preparation_time != null) ...[
                    const Icon(Icons.timer,
                        size: 20, color: ColorPalette.offBlack),
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
                        size: 20, color: ColorPalette.offBlack),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.cooking_time} min',
                      style: TextStyle(color: ColorPalette.offBlack),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12.0),

              // Tags Row
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
