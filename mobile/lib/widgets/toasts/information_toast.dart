import 'package:flutter/material.dart';
import 'package:mobile/theme/colors.dart';

class InformationToast {
  static void show({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = ColorPalette.darkgray,
    Color textColor = ColorPalette.offWhite,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
