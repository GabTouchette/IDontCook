import 'package:flutter/material.dart';
import 'package:mobile/models/recipe.dart';
import 'package:mobile/pages/recipe_detail_page.dart';
import 'package:mobile/theme/colors.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      color: ColorPalette.darkgray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.offWhite,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            recipe.description != null
                ? Text(
                    recipe.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 14,
                    ),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, color: ColorPalette.offWhite, size: 16),
                const SizedBox(width: 5),
                Text(
                  "${recipe.preparation_time} min",
                  style: const TextStyle(color: ColorPalette.offWhite),
                ),
                const SizedBox(width: 15),
                const Icon(Icons.local_fire_department,
                    color: Colors.redAccent, size: 16),
                const SizedBox(width: 5),
                Text(
                  "${recipe.cooking_time} min",
                  style: const TextStyle(color: ColorPalette.offWhite),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Ingredients",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorPalette.offWhite,
              ),
            ),
            const SizedBox(height: 5),
            Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recipe.ingredients
                        .take(3)
                        .map((ingredient) => Text(
                              "- ${ingredient.quantity} ${ingredient.unit_of_measure} ${ingredient.name}",
                              style:
                                  const TextStyle(color: ColorPalette.offWhite),
                              overflow: TextOverflow.ellipsis,
                            ))
                        .toList(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorPalette.darkgray.withOpacity(0),
                          ColorPalette.darkgray.withOpacity(1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: Column(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailPage(
                            recipe: Recipe(
                              id: -1,
                              image_url: "",
                              title: recipe.title,
                              preparation_time: recipe.preparation_time,
                              cooking_time: recipe.cooking_time,
                              ingredients: recipe.ingredients,
                              instructions: recipe.instructions,
                              description: recipe.description,
                              notes: recipe.notes,
                              tags: recipe.tags,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.menu_book_rounded,
                      color: ColorPalette.offWhite,
                      size: 18,
                    ),
                    label: const Text(
                      "Full recipe",
                      style: TextStyle(
                        color: ColorPalette.offWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                        decorationColor: ColorPalette.offWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
