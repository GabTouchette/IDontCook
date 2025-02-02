import 'package:flutter/material.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/models/recipe.dart';
import 'package:mobile/pages/recipe_detail_page.dart';
import 'package:mobile/theme/colors.dart'; // Import ColorPalette if needed

class UserRecipeCard extends StatefulWidget {
  final int recipeId;
  final bool isUser; // Add isUser to distinguish styling if necessary

  const UserRecipeCard({
    super.key,
    required this.recipeId,
    this.isUser = false, // Default to false if not provided
  });

  @override
  _UserRecipeCardState createState() => _UserRecipeCardState();
}

class _UserRecipeCardState extends State<UserRecipeCard> {
  late Future<Map<String, dynamic>> _recipeFuture;

  @override
  void initState() {
    super.initState();
    _recipeFuture = RecipeApi().getRecipeById(widget.recipeId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _recipeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Failed to load recipe.'));
        }

        if (!snapshot.hasData) {
          return Center(child: Text('Recipe not found.'));
        }

        final recipe = Recipe.fromJson(snapshot.data!);

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
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: widget.isUser
                  ? ColorPalette.lightgray
                  : ColorPalette.darkgray,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    style: TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.link,
                  color: ColorPalette.offWhite,
                  size: 28,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
