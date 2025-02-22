import 'dart:async';

import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/social_api.dart';
import 'package:i_cant_cook/models/paginated_posts/paginated_posts.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/providers/post_mixin.dart';

class ExploreProvider with ChangeNotifier, PostMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _tabIndex = 0;
  List<User> _searchResults = [];
  bool _showDropdown = false;
  int _currentPage = 1;
  String? _nextPageUrl;
  bool _isFetching = false;
  Timer? _debounceTimer;

  TextEditingController get searchController => _searchController;
  ScrollController get scrollController => _scrollController;
  int get tabIndex => _tabIndex;
  List<User> get searchResults => _searchResults;
  bool get showDropdown => _showDropdown;
  bool get isFetching => _isFetching;

  ExploreProvider() {
    _scrollController.addListener(_scrollListener);
    _fetchPosts();
  }

  void disposeProvider() {
    _searchController.dispose();
    _scrollController.dispose();
  }

  void onTabTapped(int index) {
    _tabIndex = index;
    refresh();
    notifyListeners();
  }

  @override
  Future<void> refresh() async {
    _currentPage = 1;
    clearPosts();
    await _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    if (_isFetching) return;
    _isFetching = true;
    notifyListeners();

    try {
      PaginatedPosts paginatedPosts = await SocialApi()
          .fetchPosts(page: _currentPage, category: _getCategoryFilter());
      _nextPageUrl = paginatedPosts.next;

      addPosts(paginatedPosts.results);
    } catch (e) {
      print('Error fetching posts: $e');
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  String _getCategoryFilter() {
    switch (_tabIndex) {
      case 0:
        return "all";
      case 1:
        return "trending";
      case 2:
        return "following";
      default:
        return "all";
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_nextPageUrl != null) {
        _currentPage++;
        _fetchPosts();
      }
    }
  }

  Future<void> fetchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _showDropdown = false;
      notifyListeners();
      return;
    }

    try {
      final users = await SocialApi().searchUsers(query);
      _searchResults = users;
      _showDropdown = true;
      notifyListeners();
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      fetchUsers(query);
    });
  }

  void onUserTap(BuildContext context, User selectedUser) {
    _searchController.text = selectedUser.username;
    _showDropdown = false;
    notifyListeners();
  }
}
