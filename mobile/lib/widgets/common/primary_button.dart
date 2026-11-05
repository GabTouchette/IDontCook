import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/widgets/common/pressable.dart';

/// The app's single primary call-to-action button — lime fill, sharp 4px
/// corners, bold tracked uppercase label — with built-in disabled and
/// loading states so call sites can't ship a tappable-while-saving button.
///
/// Replaces the GestureDetector+Container CTA pattern that was previously
/// hand-rolled independently in several onboarding/recipe-form screens.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 52,
  });

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final button = Opacity(
      opacity: _disabled && !isLoading ? 0.4 : 1.0,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onSecondary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: colorScheme.onSecondary),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    if (_disabled) return button;

    return Pressable(
      haptic: PressHaptic.medium,
      pressedScale: 0.97,
      child: GestureDetector(
        onTap: onPressed,
        child: button,
      ),
    );
  }
}
