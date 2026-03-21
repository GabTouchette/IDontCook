import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

// Custom extension for additional colors
extension AppColors on ColorScheme {
  Color get warning => brightness == Brightness.light
      ? ColorPalette.lightWarning
      : ColorPalette.darkWarning;

  Color get success => brightness == Brightness.light
      ? ColorPalette.lightSuccess
      : ColorPalette.darkSuccess;

  Color get info => brightness == Brightness.light
      ? ColorPalette.lightInfo
      : ColorPalette.darkInfo;

  Color get backgroundDark => brightness == Brightness.light
      ? ColorPalette.lightBgDark
      : ColorPalette.darkBgDark;

  Color get backgroundLight => brightness == Brightness.light
      ? ColorPalette.lightBgLight
      : ColorPalette.darkBgLight;

  Color get textMuted => brightness == Brightness.light
      ? ColorPalette.lightTextMuted
      : ColorPalette.darkTextMuted;

  Color get highlight => brightness == Brightness.light
      ? ColorPalette.lightHighlight
      : ColorPalette.darkHighlight;

  Color get borderMuted => brightness == Brightness.light
      ? ColorPalette.lightBorderMuted
      : ColorPalette.darkBorderMuted;
}

ThemeData lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: ColorPalette.lightBg,
    primaryColor: ColorPalette.lightPrimary,

    // Typography - elegant and readable
    textTheme: GoogleFonts.sourceSans3TextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w600,
          color: ColorPalette.lightText,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w600,
          color: ColorPalette.lightText,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: ColorPalette.lightText,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: ColorPalette.lightText,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ColorPalette.lightText,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ColorPalette.lightText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ColorPalette.lightText,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ColorPalette.lightText,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ColorPalette.lightTextMuted,
        ),
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.lightPrimary,
        foregroundColor: ColorPalette.lightBgLight,
        elevation: 2,
        shadowColor: ColorPalette.lightPrimary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.sourceSans3(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColorPalette.lightSecondary,
        foregroundColor: ColorPalette.lightText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorPalette.lightPrimary,
        side: BorderSide(color: ColorPalette.lightPrimary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: ColorPalette.lightBgLight,
      shadowColor: ColorPalette.lightPrimary.withOpacity(0.1),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: ColorPalette.lightBg,
      foregroundColor: ColorPalette.lightText,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: GoogleFonts.sourceSans3(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ColorPalette.lightText,
      ),
    ),

    colorScheme: const ColorScheme.light().copyWith(
      primary: ColorPalette.lightPrimary,
      onPrimary: ColorPalette.lightBgLight,
      secondary: ColorPalette.lightSecondary,
      onSecondary: ColorPalette.lightText,
      surface: ColorPalette.lightBgLight,
      onSurface: ColorPalette.lightText,
      surfaceContainerHighest: ColorPalette.lightBgDark,
      onSurfaceVariant: ColorPalette.lightTextMuted,
      outline: ColorPalette.lightBorder,
      outlineVariant: ColorPalette.lightBorderMuted,
      error: ColorPalette.lightDanger,
      onError: ColorPalette.lightBgLight,
      errorContainer: ColorPalette.lightDanger.withOpacity(0.15),
      onErrorContainer: ColorPalette.lightDanger,
    ),
  );
}

ThemeData darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: ColorPalette.darkBg,
    primaryColor: ColorPalette.darkPrimary,

    // Typography
    textTheme: GoogleFonts.sourceSans3TextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w600,
          color: ColorPalette.darkText,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w600,
          color: ColorPalette.darkText,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: ColorPalette.darkText,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: ColorPalette.darkText,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ColorPalette.darkText,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ColorPalette.darkText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ColorPalette.darkText,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ColorPalette.darkText,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ColorPalette.darkTextMuted,
        ),
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.darkPrimary,
        foregroundColor: ColorPalette.darkBgDark,
        elevation: 3,
        shadowColor: ColorPalette.darkPrimary.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.sourceSans3(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColorPalette.darkSecondary,
        foregroundColor: ColorPalette.darkBgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorPalette.darkPrimary,
        side: BorderSide(color: ColorPalette.darkPrimary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: ColorPalette.darkBgLight,
      shadowColor: Colors.black54,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: ColorPalette.darkBg,
      foregroundColor: ColorPalette.darkText,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: GoogleFonts.sourceSans3(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ColorPalette.darkText,
      ),
    ),

    colorScheme: const ColorScheme.dark().copyWith(
      primary: ColorPalette.darkPrimary,
      onPrimary: ColorPalette.darkBgDark,
      secondary: ColorPalette.darkSecondary,
      onSecondary: ColorPalette.darkBgDark,
      surface: ColorPalette.darkBgLight,
      onSurface: ColorPalette.darkText,
      surfaceContainerHighest: ColorPalette.darkBgDark,
      onSurfaceVariant: ColorPalette.darkTextMuted,
      outline: ColorPalette.darkBorder,
      outlineVariant: ColorPalette.darkBorderMuted,
      error: ColorPalette.darkDanger,
      onError: ColorPalette.darkBgDark,
      errorContainer: ColorPalette.darkDanger.withOpacity(0.25),
      onErrorContainer: ColorPalette.darkDanger,
    ),
  );
}
