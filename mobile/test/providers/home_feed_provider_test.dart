import 'package:flutter_test/flutter_test.dart';
import 'package:i_cant_cook/api/home_api.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/home_feed/home_feed.dart';
import 'package:i_cant_cook/models/home_module/home_module.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/providers/home_feed_provider.dart';
import 'package:i_cant_cook/services/location_service.dart';
import 'package:latlong2/latlong.dart';

/// Fake API for testing; returns scripted responses. When [feedQueue] is set,
/// successive calls return successive entries (last one repeats) so tests can
/// script a loading→ready transition; otherwise every call returns [feedToReturn].
class FakeHomeApi extends HomeApi {
  FakeHomeApi({this.feedToReturn, this.shouldFail = false, this.feedQueue});

  final HomeFeed? feedToReturn;
  final bool shouldFail;
  final List<HomeFeed?>? feedQueue;

  int callCount = 0;
  Mood? lastMoodRequested;

  @override
  Future<HomeFeed?> fetchHomeFeed({Mood? mood, double? lat, double? lng}) async {
    lastMoodRequested = mood;
    callCount++;
    if (shouldFail) return null;
    if (feedQueue != null) {
      final index = (callCount - 1).clamp(0, feedQueue!.length - 1);
      return feedQueue![index];
    }
    return feedToReturn;
  }
}

/// Location service that never touches platform channels (Geolocator) in tests.
class FakeLocationService extends LocationService {
  FakeLocationService({this.location});

  final LatLng? location;

  @override
  Future<LatLng?> currentIfPermitted() async => location;
}

/// Builds a feed containing a single `deals_rail` module in [state].
HomeFeed _feedWithDeals(String state, {String id = 'f'}) => HomeFeed(
      feed_id: id,
      blocks: [
        Block.text(text: 'hi'),
        Block.module(
          module: HomeModule(
            id: 'deals',
            moduleType: 'deals_rail',
            payload: DealsRailPayload(state: state),
          ),
        ),
      ],
    );

/// Reads the `deals_rail` state out of a loaded feed (null if absent).
String? _dealsState(HomeFeed? feed) {
  if (feed == null) return null;
  for (final block in feed.blocks) {
    final module = block.maybeMap(module: (b) => b.module, orElse: () => null);
    if (module?.moduleType == 'deals_rail') {
      final payload = module!.payload;
      return payload is DealsRailPayload ? payload.state : null;
    }
  }
  return null;
}

void main() {
  group('HomeFeedProvider', () {
    late FakeHomeApi fakeHomeApi;
    late HomeFeedProvider provider;

    HomeFeedProvider makeProvider(FakeHomeApi api) => HomeFeedProvider(
          api: api,
          locationService: FakeLocationService(),
          // Tiny backoff so poll tests finish in milliseconds.
          dealsWarmBackoff: const [
            Duration(milliseconds: 1),
            Duration(milliseconds: 1),
            Duration(milliseconds: 1),
          ],
        );

    setUp(() {
      fakeHomeApi = FakeHomeApi(feedToReturn: null);
      provider = makeProvider(fakeHomeApi);
    });

    test('initial state is empty', () {
      expect(provider.feed, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.currentMood, isNull);
    });

    test('loadFeed sets loading state and fetches feed', () async {
      final testFeed = HomeFeed(
        feed_id: 'test-123',
        blocks: [Block.text(text: 'Hello')],
      );

      provider = makeProvider(FakeHomeApi(feedToReturn: testFeed));

      await provider.loadFeed();

      expect(provider.feed, equals(testFeed));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadFeed with mood parameter', () async {
      final testFeed = HomeFeed(
        feed_id: 'test-rushed',
        context: HomeFeedContext(mood: 'rushed'),
        blocks: [Block.text(text: 'Quick meal')],
      );

      fakeHomeApi = FakeHomeApi(feedToReturn: testFeed);
      provider = makeProvider(fakeHomeApi);

      await provider.loadFeed(mood: Mood.rushed);

      expect(provider.feed, equals(testFeed));
      expect(provider.currentMood, equals(Mood.rushed));
      expect(fakeHomeApi.lastMoodRequested, equals(Mood.rushed));
      expect(provider.isLoading, isFalse);
    });

    test('loadFeed sets error when API returns null', () async {
      provider = makeProvider(FakeHomeApi(feedToReturn: null, shouldFail: true));

      await provider.loadFeed();

      expect(provider.feed, isNull);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('loadFeed clears previous error on success', () async {
      final testFeed = HomeFeed(feed_id: 'test-123', blocks: []);

      provider = makeProvider(FakeHomeApi(feedToReturn: testFeed));

      await provider.loadFeed();
      expect(provider.error, isNull);
    });

    test('selectMood refetches feed with mood', () async {
      final rushedFeed = HomeFeed(
        feed_id: 'test-rushed',
        context: HomeFeedContext(mood: 'rushed'),
        blocks: [Block.text(text: 'Quick!')],
      );

      fakeHomeApi = FakeHomeApi(feedToReturn: rushedFeed);
      provider = makeProvider(fakeHomeApi);

      await provider.selectMood(Mood.rushed);

      expect(provider.feed, equals(rushedFeed));
      expect(provider.currentMood, equals(Mood.rushed));
      expect(fakeHomeApi.lastMoodRequested, equals(Mood.rushed));
    });

    test('refresh reloads feed with current mood', () async {
      final feed1 = HomeFeed(
        feed_id: 'feed-1',
        blocks: [Block.text(text: 'First')],
      );

      fakeHomeApi = FakeHomeApi(feedToReturn: feed1);
      provider = makeProvider(fakeHomeApi);

      await provider.loadFeed();
      expect(provider.feed?.feed_id, equals('feed-1'));

      await provider.refresh();

      expect(provider.feed?.feed_id, equals('feed-1'));
    });

    test('clearFeed resets all state', () async {
      final testFeed = HomeFeed(
        feed_id: 'test-123',
        blocks: [Block.text(text: 'Hello')],
      );

      fakeHomeApi = FakeHomeApi(feedToReturn: testFeed);
      provider = makeProvider(fakeHomeApi);

      await provider.loadFeed();
      expect(provider.feed, isNotNull);

      provider.clearFeed();

      expect(provider.feed, isNull);
      expect(provider.currentMood, isNull);
      expect(provider.error, isNull);
    });

    test('polls a loading deals rail until it warms to ready', () async {
      // Backend returns a `loading` placeholder while the deals cache warms,
      // then `ready` once warm. The provider must keep re-fetching until the
      // rail resolves — even when the loading card appears on a plain load
      // (saved location), not via the "enable location" button.
      fakeHomeApi = FakeHomeApi(feedQueue: [
        _feedWithDeals('loading', id: 'f1'),
        _feedWithDeals('loading', id: 'f2'),
        _feedWithDeals('ready', id: 'f3'),
      ]);
      provider = makeProvider(fakeHomeApi);

      await provider.loadFeed();
      expect(_dealsState(provider.feed), equals('loading'));

      // Let the backoff poll run to completion.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(_dealsState(provider.feed), equals('ready'));
      expect(fakeHomeApi.callCount, greaterThanOrEqualTo(3));
    });

    test('stops polling once the deals rail is ready (no runaway refetch)',
        () async {
      fakeHomeApi = FakeHomeApi(feedToReturn: _feedWithDeals('ready'));
      provider = makeProvider(fakeHomeApi);

      await provider.loadFeed();
      await Future.delayed(const Duration(milliseconds: 50));

      // A ready rail must not trigger the poll at all — a single fetch.
      expect(fakeHomeApi.callCount, equals(1));
    });
  });
}
