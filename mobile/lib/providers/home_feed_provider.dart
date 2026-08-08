import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/home_api.dart';
import 'package:i_cant_cook/models/home_feed/home_feed.dart';
import 'package:i_cant_cook/models/mood/mood.dart';

class HomeFeedProvider extends ChangeNotifier {
  HomeFeedProvider({HomeApi? api}) : _api = api ?? HomeApi();

  final HomeApi _api;

  HomeFeed? _feed;
  bool _isLoading = false;
  String? _error;
  Mood? _currentMood;

  HomeFeed? get feed => _feed;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Mood? get currentMood => _currentMood;

  /// Fetches the home feed, optionally with a mood. On success, clears error.
  /// Does not seed the chat thread — caller (home_page) handles that.
  Future<void> loadFeed({Mood? mood}) async {
    _isLoading = true;
    _error = null;
    _currentMood = mood;
    notifyListeners();

    try {
      _feed = await _api.fetchHomeFeed(mood: mood);
      if (_feed == null) {
        _error = 'Failed to load home feed';
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects a mood and refetches the feed. Conversation stays intact or resets
  /// per home_page logic — this just updates the feed and mood state.
  Future<void> selectMood(Mood mood) async {
    await loadFeed(mood: mood);
  }

  /// Refreshes the feed (with the current mood if one was already selected).
  Future<void> refresh() async {
    await loadFeed(mood: _currentMood);
  }

  /// Clears the feed and resets mood (for when conversation is reset).
  void clearFeed() {
    _feed = null;
    _currentMood = null;
    _error = null;
    notifyListeners();
  }
}
