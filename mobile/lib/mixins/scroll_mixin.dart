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

  void disposeScroll() {
    scrollController.dispose();
  }
}
