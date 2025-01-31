import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData appTheme() {
  return ThemeData(
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 18),
    ),
    primaryColor: ColorPalette.offBlack,
    scaffoldBackgroundColor: ColorPalette.offWhite,
    buttonTheme: ButtonThemeData(
      buttonColor: ColorPalette.yellow,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.yellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
}
