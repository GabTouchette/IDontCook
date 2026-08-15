import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/widgets/recipes/placeholder_image.dart';
import 'package:i_cant_cook/api/api_config.dart';

class RecipeImage extends StatelessWidget {
  final String imageUrl;
  final Function onImagePick;
  final String? title;
  final int recipeId;

  const RecipeImage({
    Key? key,
    required this.imageUrl,
    required this.onImagePick,
    required this.recipeId,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onImagePick(),
      child: SizedBox(
        height: 340,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image layer
            imageUrl.isNotEmpty
                ? Image.network(
                    ApiConfig.resolveImageUrl(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _fallbackImage(),
                  )
                : _fallbackImage(),

            // Bottom gradient overlay for title readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.82),
                    ],
                  ),
                ),
              ),
            ),

            // Title overlaid at the bottom
            if (title != null && title!.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: Text(
                  title!,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Stack(
      children: [
        PlaceholderImageWidget(recipeId: recipeId, height: 340),
        Align(
          alignment: const Alignment(0, 0.50),
          child: Text(
            'Tap to add photo',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
