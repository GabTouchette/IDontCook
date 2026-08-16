import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/home_api.dart';
import 'package:i_cant_cook/models/home_feed/home_feed.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/services/location_service.dart';

class HomeFeedProvider extends ChangeNotifier {
  HomeFeedProvider({HomeApi? api, LocationService? locationService})
      : _api = api ?? HomeApi(),
        _location = locationService ?? LocationService();

  final HomeApi _api;
  final LocationService _location;

  HomeFeed? _feed;
  bool _isLoading = false;
  String? _error;
  Mood? _currentMood;
  DateTime? _lastLoadedAt;

  /// How long a loaded feed stays "fresh". Past this, returning to the Home
  /// tab silently refetches so the feed reshuffles (new hero, re-ranked
  /// sections) instead of showing the exact same content every visit. Short
  /// enough to feel alive, long enough that rapid tab-toggling doesn't refetch.
  static const Duration freshnessWindow = Duration(minutes: 2);

  HomeFeed? get feed => _feed;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Mood? get currentMood => _currentMood;

  /// Whether a feed has been loaded and is now past [freshnessWindow] — i.e.
  /// worth a silent background refresh on the next Home revisit.
  bool get isStale {
    final loadedAt = _lastLoadedAt;
    if (_feed == null || loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) > freshnessWindow;
  }

  /// Fetches the home feed, optionally with a mood. On success, clears error.
  /// Does not seed the chat thread — caller (home_page) handles that.
  Future<void> loadFeed({Mood? mood}) async {
    _isLoading = true;
    _error = null;
    _currentMood = mood;
    notifyListeners();

    try {
      // Auto-attach location for the nearby-deals module — silent, no prompt
      // (returns null unless permission was already granted).
      final loc = await _location.currentIfPermitted();
      _feed = await _api.fetchHomeFeed(
        mood: mood,
        lat: loc?.latitude,
        lng: loc?.longitude,
      );
      if (_feed == null) {
        _error = 'Failed to load home feed';
      } else {
        _lastLoadedAt = DateTime.now();
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
