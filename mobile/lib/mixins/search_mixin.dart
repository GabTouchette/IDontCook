import 'dart:async';

import 'package:flutter/material.dart';

mixin SearchMixin on ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _lastDebouncedQuery = '';

  String get searchQuery => _searchQuery;

  void onSearchChanged(String query, void Function(String) onDebouncedSearch) {
    _searchQuery = query;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query != _lastDebouncedQuery) {
        _lastDebouncedQuery = query;
        onDebouncedSearch(query);
      }
    });
  }

  void disposeSearch() {
    searchController.dispose();
    _debounceTimer?.cancel();
  }
}
