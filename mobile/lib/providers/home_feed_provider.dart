import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/home_api.dart';
import 'package:i_cant_cook/models/home_feed/home_feed.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/services/location_service.dart';

class HomeFeedProvider extends ChangeNotifier {
  HomeFeedProvider({
    HomeApi? api,
    LocationService? locationService,
    List<Duration>? dealsWarmBackoff,
  })  : _api = api ?? HomeApi(),
        _location = locationService ?? LocationService(),
        _dealsWarmBackoff = dealsWarmBackoff ?? _defaultDealsWarmBackoff;

  final HomeApi _api;
  final LocationService _location;
  final List<Duration> _dealsWarmBackoff;

  HomeFeed? _feed;
  bool _isLoading = false;
  String? _error;
  Mood? _currentMood;
  DateTime? _lastLoadedAt;
  bool _isPollingDeals = false;

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

    // If the freshly-loaded feed shows a deals rail still warming server-side
    // (cold cache → `loading` placeholder), start polling for the ready rail.
    // Triggered here — not from the setup card — so it works no matter how the
    // loading card appeared: a fresh page load with a saved location, or the
    // user just enabling location. Self-guards against overlapping polls.
    _maybeStartDealsPoll();
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

  /// Default backoff schedule (~30s total) for re-polling the feed while the
  /// deals rail warms. Sized to cover the worst case of the server-side warm —
  /// OSM Overpass alone has a 25s timeout — so a cold location resolves on its
  /// own instead of leaving the loading card stuck until a manual refresh.
  /// Backoff (rather than a tight fixed interval) keeps the number of full-feed
  /// refetches — each of which re-ranks the feed — to a handful. Overridable via
  /// the constructor so tests can poll on millisecond delays.
  static const List<Duration> _defaultDealsWarmBackoff = [
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 4),
    Duration(seconds: 5),
    Duration(seconds: 7),
    Duration(seconds: 9),
  ];

  /// Refetches after the user enables location. The deals rail then warms
  /// out-of-band on a cold cache (backend returns a `loading` placeholder and
  /// fetches Flipp/OSM in the background); [loadFeed] auto-starts the poll that
  /// swaps in the ready rail, so this just needs to kick off the first fetch.
  Future<void> refreshForNewLocation() async {
    await refresh();
  }

  /// Starts polling for the deals rail to finish warming, if it's currently in
  /// its `loading` state and no poll is already running.
  ///
  /// A single feed load would otherwise leave the `loading` placeholder up until
  /// the user manually refreshes minutes later. Polls (bounded, with backoff) by
  /// re-fetching the feed until the rail resolves to `ready`/empty. The re-entry
  /// guard is essential: each [refresh] inside the loop calls [loadFeed], which
  /// calls this again — the guard stops that from spawning nested polls.
  void _maybeStartDealsPoll() {
    if (_isPollingDeals || !_dealsWarming) return;
    _isPollingDeals = true;
    Future(() async {
      try {
        for (final delay in _dealsWarmBackoff) {
          if (!_dealsWarming) return;
          await Future.delayed(delay);
          await refresh();
        }
      } finally {
        _isPollingDeals = false;
      }
    });
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
