import 'package:flutter/material.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/theme/theme.dart';

/// App-wide toast/snackbar surface.
///
/// Prefer the semantic shortcuts — [InformationToast.success],
/// [InformationToast.error], [InformationToast.warning],
/// [InformationToast.info] — over calling [show] directly. They force an
/// explicit intent at the call site so an error can never accidentally be
/// styled as a neutral info toast by omitting `type`.
///
/// Reach for [show] only when you need an action affordance
/// (`actionLabel`/`onAction`) or a non-default `duration`.
///
/// Convention: messages are sentence case, end with a period, and never
/// interpolate a raw exception. Use [messageForError] to turn a thrown error
/// into user-facing copy.
class InformationToast {
  /// Neutral, informational toast.
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        context: context,
        message: message,
        type: ToastType.info,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Positive confirmation that an action succeeded.
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        context: context,
        message: message,
        type: ToastType.success,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Non-blocking caution — the action didn't fail but the user should notice.
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        context: context,
        message: message,
        type: ToastType.warning,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Something failed. Pass [messageForError] output when surfacing an
  /// exception rather than interpolating it raw.
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        context: context,
        message: message,
        type: ToastType.error,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Turn an arbitrary thrown [error] into user-facing copy: strips the
  /// `Exception: ` prefix Dart prepends and falls back to [fallback] when the
  /// result would be empty. Never exposes a raw stack-trace-like string.
  static String messageForError(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final text =
        error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    return text.isEmpty ? fallback : text;
  }

  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    ToastType type = ToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
    bool replacePrevious = false,
  }) {
    final Color toastBackgroundColor;
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

    final messenger = ScaffoldMessenger.of(context);
    if (replacePrevious) messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
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
