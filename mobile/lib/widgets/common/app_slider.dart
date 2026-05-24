import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable slider with a square thumb and the app's lime highlight color.
///
/// Use [AppRangeSlider] for range-based (two-handle) sliders.
class AppSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double>? onChanged;

  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
  });

  static const _lime = Color(0xFFCAFF00);

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: _lime,
        inactiveTrackColor:
            Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        thumbColor: _lime,
        overlayColor: _lime.withValues(alpha: 0.15),
        trackHeight: 2,
        thumbShape: const _SquareSliderThumbShape(thumbSize: 14),
        valueIndicatorColor: Theme.of(context).colorScheme.onSurface,
        valueIndicatorTextStyle: GoogleFonts.spaceGrotesk(
          color: Theme.of(context).colorScheme.surface,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        showValueIndicator: ShowValueIndicator.onDrag,
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}

/// A reusable range slider with square thumbs and the app's lime highlight color.
class AppRangeSlider extends StatelessWidget {
  final RangeValues values;
  final double min;
  final double max;
  final int? divisions;
  final RangeLabels? labels;
  final ValueChanged<RangeValues>? onChanged;

  const AppRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.labels,
  });

  static const _lime = Color(0xFFCAFF00);

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: _lime,
        inactiveTrackColor:
            Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        thumbColor: _lime,
        overlayColor: _lime.withValues(alpha: 0.15),
        trackHeight: 2,
        rangeThumbShape: const _SquareRangeSliderThumbShape(thumbSize: 14),
        valueIndicatorColor: Theme.of(context).colorScheme.onSurface,
        valueIndicatorTextStyle: GoogleFonts.spaceGrotesk(
          color: Theme.of(context).colorScheme.surface,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        showValueIndicator: ShowValueIndicator.onDrag,
        values: values,
        min: min,
        max: max,
        divisions: divisions,
        labels: labels,
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Square thumb shapes ────────────────────────────────────────────────────

class _SquareSliderThumbShape extends SliderComponentShape {
  final double thumbSize;

  const _SquareSliderThumbShape({this.thumbSize = 14});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size(thumbSize, thumbSize);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? const Color(0xFFCAFF00)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(center: center, width: thumbSize, height: thumbSize),
      paint,
    );
  }
}

class _SquareRangeSliderThumbShape extends RangeSliderThumbShape {
  final double thumbSize;

  const _SquareRangeSliderThumbShape({this.thumbSize = 14});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size(thumbSize, thumbSize);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = true,
    bool isOnTop = false,
    bool isPressed = false,
    required SliderThemeData sliderTheme,
    TextDirection textDirection = TextDirection.ltr,
    required Thumb thumb,
  }) {
    final canvas = context.canvas;
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? const Color(0xFFCAFF00)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(center: center, width: thumbSize, height: thumbSize),
      paint,
    );
  }
}
