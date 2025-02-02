import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/models/recipe.dart';
import 'package:mobile/pages/recipe_detail_page.dart';
import 'package:mobile/theme/colors.dart';

class RecipeTile extends StatelessWidget {
  final Recipe recipe;

  const RecipeTile({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  Widget getSmallRecipeImage(String? imageUrl) {
    final random = Random();
    int imageNumber = random.nextInt(11) + 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            )
          : Container(
              color: ColorPalette.offWhite,
              height: 80,
              width: 80,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/stock_food_$imageNumber.jpg',
                    fit: BoxFit.cover,
                    height: 80,
                    width: 80,
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.image,
                      color: ColorPalette.lightgray,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        );
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
                  getSmallRecipeImage(recipe.image_url),
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
                          maxLines: 1,
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
