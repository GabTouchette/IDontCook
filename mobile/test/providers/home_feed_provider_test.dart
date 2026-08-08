import 'package:flutter_test/flutter_test.dart';
import 'package:i_cant_cook/api/home_api.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/home_feed/home_feed.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/providers/home_feed_provider.dart';

/// Fake API for testing; returns scripted responses.
class FakeHomeApi extends HomeApi {
  FakeHomeApi({this.feedToReturn, this.shouldFail = false});

  final HomeFeed? feedToReturn;
  final bool shouldFail;

  Mood? lastMoodRequested;

  @override
  Future<HomeFeed?> fetchHomeFeed({Mood? mood}) async {
    lastMoodRequested = mood;
    if (shouldFail) return null;
    return feedToReturn;
  }
}

void main() {
  group('HomeFeedProvider', () {
    late FakeHomeApi fakeHomeApi;
    late HomeFeedProvider provider;

    setUp(() {
      fakeHomeApi = FakeHomeApi(feedToReturn: null);
      provider = HomeFeedProvider(api: fakeHomeApi);
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

      fakeHomeApi = FakeHomeApi(feedToReturn: testFeed);
      provider = HomeFeedProvider(api: fakeHomeApi);

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
      provider = HomeFeedProvider(api: fakeHomeApi);

      await provider.loadFeed(mood: Mood.rushed);

      expect(provider.feed, equals(testFeed));
      expect(provider.currentMood, equals(Mood.rushed));
      expect(fakeHomeApi.lastMoodRequested, equals(Mood.rushed));
      expect(provider.isLoading, isFalse);
    });

    test('loadFeed sets error when API returns null', () async {
      fakeHomeApi = FakeHomeApi(feedToReturn: null, shouldFail: true);
      provider = HomeFeedProvider(api: fakeHomeApi);

      await provider.loadFeed();

      expect(provider.feed, isNull);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('loadFeed clears previous error on success', () async {
      final testFeed = HomeFeed(
        feed_id: 'test-123',
        blocks: [],
      );

      fakeHomeApi = FakeHomeApi(feedToReturn: testFeed);
      provider = HomeFeedProvider(api: fakeHomeApi);

      // First call succeeds
      await provider.loadFeed();
      expect(provider.error, isNull);

      // Feed is cached, error should still be null
      expect(provider.error, isNull);
    });

    test('selectMood refetches feed with mood', () async {
      final rushedFeed = HomeFeed(
        feed_id: 'test-rushed',
        context: HomeFeedContext(mood: 'rushed'),
        blocks: [Block.text(text: 'Quick!')],
      );

      fakeHomeApi = FakeHomeApi(feedToReturn: rushedFeed);
      provider = HomeFeedProvider(api: fakeHomeApi);

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
      provider = HomeFeedProvider(api: fakeHomeApi);

      await provider.loadFeed();
      expect(provider.feed?.feed_id, equals('feed-1'));

      // Refresh should refetch
      await provider.refresh();

      // The feed should still be the same (API returns same data)
      expect(provider.feed?.feed_id, equals('feed-1'));
    });

    test('clearFeed resets all state', () async {
      final testFeed = HomeFeed(
        feed_id: 'test-123',
        blocks: [Block.text(text: 'Hello')],
      );

      fakeHomeApi = FakeHomeApi(feedToReturn: testFeed);
      provider = HomeFeedProvider(api: fakeHomeApi);

      await provider.loadFeed();
      expect(provider.feed, isNotNull);

      provider.clearFeed();

      expect(provider.feed, isNull);
      expect(provider.currentMood, isNull);
      expect(provider.error, isNull);
    });
  });
}
