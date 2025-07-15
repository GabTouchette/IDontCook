import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/social_api.dart';
import 'package:i_cant_cook/models/post/post.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/mixins/post_mixin.dart';
import 'package:i_cant_cook/mixins/search_mixin.dart';
import 'package:i_cant_cook/mixins/scroll_mixin.dart';
import 'package:i_cant_cook/mixins/pagination_mixin.dart';

class SocialProvider
    with
        ChangeNotifier,
        PostMixin,
        SearchMixin,
        ScrollMixin,
        PaginationMixin<Post> {
  int _tabIndex = 0;
  List<User> _searchResults = [];
  bool _showDropdown = false;

  int get tabIndex => _tabIndex;
  List<User> get searchResults => _searchResults;
  bool get showDropdown => _showDropdown;

  SocialProvider() {
    initScrollListener(fetchNextPage);
    fetchInitialItems();
  }

  void onTabTapped(int index) {
    _tabIndex = index;
    refresh();
    notifyListeners();
  }

  @override
  Future<List<Post>> fetchItems(int page) async {
    final paginated = await SocialApi().fetchPosts(
      page: page,
      category: _getCategoryFilter(),
    );
    setNextPageUrl(paginated.next);
    addPosts(paginated.results);
    return paginated.results;
  }

  @override
  Future<void> refresh() async {
    clearPosts();
    await fetchInitialItems();
  }

  String _getCategoryFilter() {
    return switch (_tabIndex) {
      0 => 'all',
      1 => 'trending',
      2 => 'following',
      _ => 'all',
    };
  }

  void handleSearchChanged(String query) {
    onSearchChanged(query, fetchUsers);
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
    } catch (e) {
      print('Error searching users: $e');
    }
    notifyListeners();
  }

  void onUserTap(BuildContext context, User selectedUser) {
    searchController.text = selectedUser.username;
    _showDropdown = false;
    notifyListeners();
  }

  void disposeProvider() {
    disposeSearch();
    disposeScroll();
  }
}
