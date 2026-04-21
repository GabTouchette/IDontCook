import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';

class BigRecipeTile extends StatelessWidget {
  final RecipePreview recipe;

  const BigRecipeTile({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  Widget getBigRecipeImage(String? thumbanilUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: thumbanilUrl != null && thumbanilUrl.isNotEmpty
          ? Image.network(
              thumbanilUrl,
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big Title
              Text(
                recipe.title,
                style: GoogleFonts.nunito(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12.0),

              // Image and Description Row
              Row(
                children: [
                  Expanded(
                    child: getBigRecipeImage(recipe.thumbnail_url),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      recipe.description ?? 'No description available.',
                      style: GoogleFonts.nunito(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
                    Icon(Icons.timer,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.preparation_time} min',
                      style: GoogleFonts.nunito(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (recipe.preparation_time != null &&
                      recipe.cooking_time != null)
                    const SizedBox(width: 12),
                  if (recipe.cooking_time != null) ...[
                    Icon(Icons.local_fire_department,
                        size: 20, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.cooking_time} min',
                      style: GoogleFonts.nunito(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
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
                  children: [
                    // First, we calculate the maximum number of tags we want to display
                    for (int i = 0;
                        i < (recipe.tags!.length > 5 ? 5 : recipe.tags!.length);
                        i++)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              recipe.tags![i],
                              style: GoogleFonts.nunito(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6.0),
                          ],
                        ),
                      ),
                    // If there are more than 5 tags, display the ellipsis
                    if (recipe.tags!.length > 5)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+ ${recipe.tags!.length - 5} others',
                              style: GoogleFonts.nunito(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6.0),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
