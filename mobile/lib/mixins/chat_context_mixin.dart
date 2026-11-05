import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/chat/chat_page_context.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:provider/provider.dart';

/// Lets a page register what the user is currently looking at with the global
/// chat (see [ChatProvider.setPageContext]). Call [registerChatContext] from
/// `build` (or whenever the page's data changes); the mixin clears the context
/// on `dispose` if this page still owns it.
mixin ChatContextRegistrar<T extends StatefulWidget> on State<T> {
  void registerChatContext(ChatPageContext pageContext) {
    context.read<ChatProvider>().setPageContext(pageContext, this);
  }

  @override
  void dispose() {
    context.read<ChatProvider>().clearPageContext(this);
    super.dispose();
  }
}

/// Registers chat page context from a `StatelessWidget` (which has no `dispose`
/// to clear on). Safe for tab surfaces: the next visible surface overwrites
/// ownership on its own build, so context never goes stale between tabs. Pass a
/// stable [owner] (a top-level sentinel) per page.
void setChatPageContext(
    BuildContext context, ChatPageContext pageContext, Object owner) {
  context.read<ChatProvider>().setPageContext(pageContext, owner);
}
