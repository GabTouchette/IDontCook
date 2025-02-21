import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/api/social_api.dart';
import 'package:mobile/models/paginated_posts/paginated_posts.dart';
import 'package:mobile/models/post/post.dart';
import 'package:mobile/models/user/user.dart';

class ExploreProvider with ChangeNotifier {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _tabIndex = 0;
  List<Post> _posts = [];
  List<User> _searchResults = [];
  bool _showDropdown = false;
  int _currentPage = 1;
  String? _nextPageUrl;
  bool _isFetching = false;
  Timer? _debounceTimer;

  TextEditingController get searchController => _searchController;
  ScrollController get scrollController => _scrollController;
  int get tabIndex => _tabIndex;
  List<Post> get posts => _posts;
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
    _refresh();
    notifyListeners();
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    _posts.clear();
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

      // Append new posts to the existing list
      _posts.addAll(paginatedPosts.results);
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

  Future<void> handleVote(int postId, int voteValue) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return; //

    final post = _posts[postIndex];
    final currentVote = post.user_vote;
    final newVote = currentVote == voteValue ? 0 : voteValue;

    final success = await SocialApi().createVote(postId, {"value": newVote});
    if (success) {
      final updatedPost = post.copyWith(
        user_vote: newVote,
        upvote_count: post.upvote_count +
            (newVote == 1 ? 1 : 0) -
            (currentVote == 1 ? 1 : 0),
        downvote_count: post.downvote_count +
            (newVote == -1 ? 1 : 0) -
            (currentVote == -1 ? 1 : 0),
      );

      _posts[postIndex] = updatedPost;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int userId, int postId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return; // Post not found

    final post = _posts[postIndex];
    final isLiked = post.user_liked;

    final success = isLiked
        ? await SocialApi().deleteLike(postId)
        : await SocialApi().createLike(
            {"user": userId, "post": postId, "comment": null}, postId);

    if (success) {
      // Update the post's like state
      final updatedPost = post.copyWith(
        user_liked: !isLiked,
        like_count: post.like_count + (isLiked ? -1 : 1),
      );

      _posts[postIndex] = updatedPost;
      notifyListeners();
    }
  }

  void incrementCommentCount(int postId) {
    final post = _posts.firstWhere((post) => post.id == postId);
    final updatedPost = post.copyWith(comment_count: post.comment_count + 1);
    _posts[_posts.indexWhere((p) => p.id == postId)] = updatedPost;
    notifyListeners();
  }
}
