import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/home_api.dart';
import 'package:i_cant_cook/models/home_feed/home_feed.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
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

  /// Backoff schedule (~30s total) for re-polling the feed while the deals rail
  /// warms. Sized to cover the worst case of the server-side warm — OSM Overpass
  /// alone has a 25s timeout — so a cold location resolves on its own instead of
  /// leaving the loading card stuck until a manual refresh. Backoff (rather than
  /// a tight fixed interval) keeps the number of full-feed refetches — each of
  /// which re-ranks the feed — to a handful.
  static const List<Duration> _dealsWarmBackoff = [
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 4),
    Duration(seconds: 5),
    Duration(seconds: 7),
    Duration(seconds: 9),
  ];

  /// Refetches after the user enables location, then polls until the nearby
  /// deals rail finishes warming server-side.
  ///
  /// The rail warms out-of-band on a cold cache: the backend returns a
  /// `loading` placeholder and kicks off the Flipp/OSM fetch in the background,
  /// so a single refresh would leave the placeholder up until the user manually
  /// refreshes minutes later. This polls (bounded, with backoff) to swap in the
  /// ready rail — or stops early once it's ready/empty. Lives on the provider,
  /// not the setup card, so it survives that card being replaced mid-poll.
  Future<void> refreshForNewLocation() async {
    await refresh();
    for (final delay in _dealsWarmBackoff) {
      if (!_dealsWarming) return;
      await Future.delayed(delay);
      await refresh();
    }
  }

  /// True while the feed contains a `deals_rail` module still in its `loading`
  /// state (location known, deals warming server-side). False once it resolves
  /// to a ready rail or drops out of the feed (no deals for this location).
  bool get _dealsWarming {
    final feed = _feed;
    if (feed == null) return false;
    for (final block in feed.blocks) {
      final module = block.maybeMap(
        module: (b) => b.module,
        orElse: () => null,
      );
      if (module == null || module.moduleType != 'deals_rail') continue;
      final payload = module.payload;
      return payload is DealsRailPayload && payload.isLoading;
    }
    return false;
  }

  /// Clears the feed and resets mood (for when conversation is reset).
  void clearFeed() {
    _feed = null;
    _currentMood = null;
    _error = null;
    notifyListeners();
  }
}
