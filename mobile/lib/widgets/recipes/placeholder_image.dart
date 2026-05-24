
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaceholderImageWidget extends StatelessWidget {
  final int recipeId;
  final int height;
  final String? title;

  const PlaceholderImageWidget({
    Key? key,
    required this.recipeId,
    this.height = 120,
    this.title,
  }) : super(key: key);

  // Background options
  static const _backgrounds = [
    Color(0xFFE0DFD9), // warm grey
    Color(0xFF0A0A0A), // black
  ];

  // Icon highlight colours (randomly applied)
  static const _iconColors = [
    Color(0xFFFFD600), // vivid yellow
    Color(0xFFFFE066), // soft yellow
    Color(0xFFFFC107), // amber yellow
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _backgrounds[recipeId % _backgrounds.length];
    final iconColor = _iconColors[recipeId % _iconColors.length];
    final isLarge = height >= 160;
    final iconSize = height * (isLarge ? 0.40 : 0.44);

    return SizedBox(
      height: height.toDouble(),
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Solid background
          Container(color: bg),

          // Diagonal stripe texture
          CustomPaint(
            painter: _DiagonalStripePainter(
              stripeColor: iconColor.withOpacity(0.08),
              stripeWidth: isLarge ? 20.0 : 12.0,
              gap: isLarge ? 20.0 : 12.0,
            ),
          ),

          // Utensil icon — centred
          Center(
            child: Icon(
              Icons.restaurant,
              color: iconColor.withOpacity(0.85),
              size: iconSize,
            ),
          ),

          // "NO PHOTO" label — only on large tiles
          if (isLarge)
            Positioned(
              bottom: 14,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: iconColor.withOpacity(0.12),
                child: Text(
                  'NO PHOTO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: iconColor.withOpacity(0.6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Diagonal stripe background ────────────────────────────────────────────────
class _DiagonalStripePainter extends CustomPainter {
  final Color stripeColor;
  final double stripeWidth;
  final double gap;

  const _DiagonalStripePainter({
    required this.stripeColor,
    required this.stripeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor
      ..style = PaintingStyle.fill;

    final step = stripeWidth + gap;
    final extent = size.width + size.height;

    for (double i = -size.height; i < extent; i += step) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + stripeWidth, 0)
        ..lineTo(i + stripeWidth + size.height, size.height)
        ..lineTo(i + size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter old) =>
      old.stripeColor != stripeColor ||
      old.stripeWidth != stripeWidth ||
      old.gap != gap;
}
