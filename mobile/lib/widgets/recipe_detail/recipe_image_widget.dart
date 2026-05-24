import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecipeImage extends StatelessWidget {
  final String imageUrl;
  final Function onImagePick;
  final String? title;

  const RecipeImage({
    Key? key,
    required this.imageUrl,
    required this.onImagePick,
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
                    imageUrl,
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
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Faint grid lines for texture
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // Giant watermark icon
          Center(
            child: Icon(
              Icons.restaurant,
              size: 160,
              color: Colors.white.withOpacity(0.03),
            ),
          ),
          // Lime accent bar top-left
          const Positioned(
            left: 20,
            top: 24,
            child: SizedBox(
              width: 36,
              height: 3,
              child: ColoredBox(color: Color(0xFFCAFF00)),
            ),
          ),
          // Centered CTA block
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  color: const Color(0xFFCAFF00),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: Color(0xFF0A0A0A),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'ADD PHOTO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.0,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
