import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

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
      surface: ColorPalette.lightBg,
      surfaceBright: ColorPalette.lightBgLight,
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
      background: ColorPalette.darkBg,
      surface: ColorPalette.darkBgLight,
      error: ColorPalette.darkDanger,
    ),
  );
}
