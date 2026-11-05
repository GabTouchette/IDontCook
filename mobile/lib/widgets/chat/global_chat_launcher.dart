import 'package:flutter/material.dart';
import 'package:i_cant_cook/widgets/chat/global_chat_sheet.dart';
import 'package:i_cant_cook/widgets/sheets/app_sheet.dart';

/// Opens the app-wide assistant [GlobalChatSheet] as a modal bottom sheet.
/// [initialQuery] is auto-sent on open (e.g. an ingredient long-press action).
void openGlobalChat(BuildContext context, {String? initialQuery}) {
  showAppSheet(
    context: context,
    builder: (_) => GlobalChatSheet(initialQuery: initialQuery),
  );
}

/// The floating assistant button shown in the bottom-right corner of the main
/// app surfaces. Mounts above page content; whichever page it sits on registers
/// its context via `ChatProvider.setPageContext`, so opening the chat here
/// carries that context.
class GlobalChatLauncher extends StatelessWidget {
  /// Distance from the bottom edge. Surfaces with a bottom nav bar pass a
  /// larger value so the button clears it.
  final double bottom;
  final double right;

  const GlobalChatLauncher({super.key, this.bottom = 24, this.right = 24});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      child: GestureDetector(
        onTap: () => openGlobalChat(context),
        child: Container(
          width: 56,
          height: 56,
          color: Theme.of(context).colorScheme.secondary,
          child: Icon(
            Icons.chat_bubble_outline,
            color: Theme.of(context).colorScheme.onSecondary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
