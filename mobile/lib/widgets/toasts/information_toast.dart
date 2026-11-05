import 'package:flutter/material.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/theme/theme.dart';

class InformationToast {
  static void show({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    ToastType type = ToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    Color toastBackgroundColor;

    if (backgroundColor != null) {
      toastBackgroundColor = backgroundColor;
    } else {
      switch (type) {
        case ToastType.info:
          toastBackgroundColor = Theme.of(context).colorScheme.info;
          break;
        case ToastType.warning:
          toastBackgroundColor = Theme.of(context).colorScheme.warning;
          break;
        case ToastType.success:
          toastBackgroundColor = Theme.of(context).colorScheme.success;
          break;
        case ToastType.error:
          toastBackgroundColor = Theme.of(context).colorScheme.error;
          break;
      }
    }

    // Haptic feedback based on severity
    switch (type) {
      case ToastType.success:
        HapticService.notificationSuccess();
        break;
      case ToastType.warning:
        HapticService.notificationWarning();
        break;
      case ToastType.error:
        HapticService.notificationError();
        break;
      case ToastType.info:
        HapticService.selectionClick();
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: toastBackgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
