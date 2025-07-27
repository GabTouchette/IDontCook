import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

// Custom extension to add all ColorPalette colors to ColorScheme
extension CustomColors on ColorScheme {
  // Semantic colors
  Color get warning => brightness == Brightness.light
      ? ColorPalette.lightWarning
      : ColorPalette.darkWarning;

  Color get success => brightness == Brightness.light
      ? ColorPalette.lightSuccess
      : ColorPalette.darkSuccess;

  Color get info => brightness == Brightness.light
      ? ColorPalette.lightInfo
      : ColorPalette.darkInfo;

  // Background variants
  Color get backgroundDark => brightness == Brightness.light
      ? ColorPalette.lightBgDark
      : ColorPalette.darkBgDark;

  Color get backgroundLight => brightness == Brightness.light
      ? ColorPalette.lightBgLight
      : ColorPalette.darkBgLight;

  // Text variants
  Color get textMuted => brightness == Brightness.light
      ? ColorPalette.lightTextMuted
      : ColorPalette.darkTextMuted;

  // Interactive colors
  Color get highlight => brightness == Brightness.light
      ? ColorPalette.lightHighlight
      : ColorPalette.darkHighlight;

  // Border variants
  Color get borderMuted => brightness == Brightness.light
      ? ColorPalette.lightBorderMuted
      : ColorPalette.darkBorderMuted;
}

ThemeData lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: ColorPalette.lightBg,
    primaryColor: ColorPalette.lightPrimary,
    textTheme: GoogleFonts.nunitoTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: ColorPalette.lightText),
        bodyMedium: TextStyle(fontSize: 18, color: ColorPalette.lightText),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.lightHighlight,
        foregroundColor: ColorPalette.lightText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    colorScheme: const ColorScheme.light().copyWith(
      primary: ColorPalette.lightPrimary,
      secondary: ColorPalette.lightSecondary,
      surface: ColorPalette.lightBgLight,
      surfaceContainerHighest: ColorPalette.lightBgDark,
      onSurface: ColorPalette.lightText,
      onSurfaceVariant: ColorPalette.lightTextMuted,
      outline: ColorPalette.lightBorder,
      outlineVariant: ColorPalette.lightBorderMuted,
      error: ColorPalette.lightDanger,
    ),
  );
}

ThemeData darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ColorPalette.darkBg,
    primaryColor: ColorPalette.darkPrimary,
    textTheme: GoogleFonts.nunitoTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: ColorPalette.darkText),
        bodyMedium: TextStyle(fontSize: 18, color: ColorPalette.darkText),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.darkHighlight,
        foregroundColor: ColorPalette.darkText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: ColorPalette.darkPrimary,
      secondary: ColorPalette.darkSecondary,
      surface: ColorPalette.darkBgLight,
      surfaceContainerHighest: ColorPalette.darkBgDark,
      onSurface: ColorPalette.darkText,
      onSurfaceVariant: ColorPalette.darkTextMuted,
      outline: ColorPalette.darkBorder,
      outlineVariant: ColorPalette.darkBorderMuted,
      error: ColorPalette.darkDanger,
      onPrimary: ColorPalette.darkBgDark,
      onSecondary: ColorPalette.darkBgDark,
      onError: ColorPalette.darkBgDark,
    ),
  );
}
