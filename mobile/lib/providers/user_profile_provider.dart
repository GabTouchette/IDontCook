import 'package:flutter/material.dart';
import 'package:mobile/api/auth_api.dart';
import 'package:mobile/api/social_api.dart';
import 'package:mobile/models/recipe/recipe.dart';
import 'package:mobile/models/user/user.dart';
import 'package:mobile/providers/post_mixin.dart';

class UserProfileProvider with ChangeNotifier, PostMixin {
  User? _user;
  List<Recipe> _recipes = [];
  bool _isFollowing = false;
  bool _isCurrentUser = false;
  int _followerCount = 0;
  bool _isLoading = false;
  int tabIndex = 0;

  User? get user => _user;
  List<Recipe> get recipes => _recipes;
  bool get isFollowing => _isFollowing;
  bool get isCurrentUser => _isCurrentUser;
  int get followerCount => _followerCount;
  bool get isLoading => _isLoading;

  UserProfileProvider({User? user}) {
    _initialize(user);
  }

  Future<void> _initialize(User? user) async {
    _isLoading = true;
    notifyListeners();

    final currentUser = await AuthApi.getUser();
    if (user == null) {
      _user = currentUser;
      _isCurrentUser = true;
    } else {
      _user = await SocialApi().fetchUserInfo(user.id);
    }

    try {
      _followerCount = _user!.follower_count ?? 0;

      _recipes = await SocialApi().fetchUserRecipes(_user!.id);
      final posts = await SocialApi().fetchUserPosts(_user!.id);

      // Add posts using the mixin
      addPosts(posts);

      posts.sort((a, b) {
        final aVotes = a.upvote_count - a.downvote_count;
        final bVotes = b.upvote_count - b.downvote_count;
        return bVotes.compareTo(aVotes);
      });

      if (currentUser != null) {
        _isCurrentUser = currentUser.id == _user!.id;
        _isFollowing = await SocialApi().isUserFollowing(_user!.id);
      }
    } catch (e) {
      print('Error initializing user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTabIndex(int index) {
    tabIndex = index;
    notifyListeners();
  }

  Future<void> toggleFollowUser() async {
    if (_user == null) return;

    bool success;

    if (_isFollowing) {
      success = await SocialApi().deleteFollow(_user!.id);
    } else {
      success = await SocialApi().createFollow(_user!.id);
    }
    if (success) {
      _isFollowing = !_isFollowing;
      _followerCount += _isFollowing ? 1 : -1;
      notifyListeners();
    }
  }
}