import 'package:flutter/material.dart';

mixin ScrollMixin on ChangeNotifier {
  final ScrollController scrollController = ScrollController();

  void initScrollListener(VoidCallback onBottomReached) {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent) {
        onBottomReached();
      }
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void disposeScroll() {
    scrollController.dispose();
  }
}
