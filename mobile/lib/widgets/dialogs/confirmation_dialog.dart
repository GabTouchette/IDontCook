import 'package:flutter/material.dart';
import 'package:i_cant_cook/theme/colors.dart';

class ConfirmationDialog extends StatelessWidget {
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmationDialog({
    Key? key,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorPalette.darkgray,
      title: const Text(
        "Confirm Action",
        style: TextStyle(color: ColorPalette.offWhite),
      ),
      content: Text(
        message,
        style: const TextStyle(color: ColorPalette.offWhite),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text("Confirm", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
