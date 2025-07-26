import 'package:flutter/material.dart';

mixin PaginationMixin<T> on ChangeNotifier {
  int _currentPage = 1;
  String? _nextPageUrl;
  bool _isFetching = false;
  bool _isLoading = false;
  final List<T> _items = [];

  int get currentPage => _currentPage;
  bool get isFetching => _isFetching;
  bool get isLoading => _isLoading;
  List<T> get items => _items;

  Future<List<T>> fetchItems(int page);

  Future<void> fetchInitialItems() async {
    _currentPage = 1;
    _nextPageUrl = null;
    _items.clear();
    _isLoading = true;
    notifyListeners();
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (_isFetching) return;
    _isFetching = true;
    notifyListeners();

    try {
      final fetched = await fetchItems(_currentPage);
      _items.addAll(fetched);
    } catch (e) {
      print("Error in pagination fetch: $e");
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNextPage() async {
    if (_nextPageUrl != null && !_isFetching) {
      _currentPage++;
      await _fetchData();
    }
  }

  void setNextPageUrl(String? next) {
    _nextPageUrl = next;
  }

  void refreshItems() async {
    await fetchInitialItems();
  }
}
