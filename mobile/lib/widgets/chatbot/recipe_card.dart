import 'package:flutter/material.dart';
import 'package:mobile/models/ingredient.dart';
import 'package:mobile/models/recipe.dart';
import 'package:mobile/pages/recipe_detail_page.dart';
import 'package:mobile/theme/colors.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final int cookingTime;
  final int preparationTime;
  final List<String> tags;
  final String description;
  final String notes;

  const RecipeCard({
    super.key,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.cookingTime,
    required this.preparationTime,
    required this.tags,
    required this.description,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    title,
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
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ColorPalette.offWhite,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, color: ColorPalette.offWhite, size: 16),
                const SizedBox(width: 5),
                Text(
                  "$preparationTime min",
                  style: const TextStyle(color: ColorPalette.offWhite),
                ),
                const SizedBox(width: 15),
                const Icon(Icons.local_fire_department,
                    color: Colors.redAccent, size: 16),
                const SizedBox(width: 5),
                Text(
                  "$cookingTime min",
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
                    children: ingredients
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
                          ColorPalette.darkgray.withValues(alpha: 0),
                          ColorPalette.darkgray.withValues(alpha: 255),
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
                              title: title,
                              preparation_time: preparationTime,
                              cooking_time: cookingTime,
                              ingredients: ingredients,
                              instructions: instructions,
                              description: description,
                              notes: notes,
                              tags: tags,
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
