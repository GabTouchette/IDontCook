import 'package:flutter/material.dart';
import 'package:mobile/theme/colors.dart';

class InformationDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const InformationDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorPalette.darkgray,
      title: Text(
        title,
        style: const TextStyle(color: ColorPalette.offWhite),
      ),
      content: Text(
        message,
        style: const TextStyle(color: ColorPalette.offWhite),
      ),
      actions: [
        TextButton(
          onPressed: () => onConfirm(),
          child: const Text("OK", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
