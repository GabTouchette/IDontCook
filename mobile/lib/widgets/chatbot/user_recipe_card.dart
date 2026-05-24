import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';

class UserRecipeCard extends StatefulWidget {
  final int recipeId;
  final bool isUser;

  const UserRecipeCard({
    super.key,
    required this.recipeId,
    this.isUser = false,
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
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onSurface,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                'Failed to load recipe.',
                style: GoogleFonts.spaceGrotesk(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                'Recipe not found.',
                style: GoogleFonts.spaceGrotesk(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final recipe = Recipe.fromJson(snapshot.data!);

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
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34,
                  height: 34,
                  color: const Color(0xFFCAFF00),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Color(0xFF0A0A0A),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
