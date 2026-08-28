import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/features/search/discovery_controller.dart';
import 'package:hi_hat/models/track.dart';
import 'package:hi_hat/services/artist_preferences_store.dart';
import 'package:hi_hat/services/discovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

TrackSummary track(String id, {String artist = 'Artist'}) => TrackSummary(
  id: 'monochrome:$id',
  provider: 'monochrome',
  providerTrackId: id,
  title: 'Track $id',
  artist: artist,
  quality: const AudioQuality(),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  test('artist genre mapping combines known artists and selected genres', () {
    final seeds = DiscoveryService.genreSeedsFor(
      const ['Daft Punk', 'Unknown Artist'],
      const {'Ambient'},
    );

    expect(seeds, containsAll(['electronic', 'dance', 'ambient']));
  });

  test('unknown artists fall back to neutral discovery search seeds', () {
    expect(
      DiscoveryService.genreSeedsFor(const ['Unknown Artist'], const {}),
      DiscoveryService.fallbackSeeds,
    );
  });

  test('feed composition deduplicates provider IDs and shuffles', () {
    final input = [
      track('1'),
      track('2'),
      track('1'),
      track('3'),
      track('4'),
      track('5'),
    ];

    final first = DiscoveryService.dedupeAndShuffle(input, random: Random(27));
    final second = DiscoveryService.dedupeAndShuffle(input, random: Random(27));

    expect(first.map((item) => item.providerTrackId).toSet().length, 5);
    expect(
      first.map((item) => item.providerTrackId),
      second.map((item) => item.providerTrackId),
    );
    expect(
      first.map((item) => item.providerTrackId).toList(),
      isNot(['1', '2', '3', '4', '5']),
    );
  });

  test('feed composition respects the discovery track cap', () {
    final input = List.generate(70, (index) => track('$index'));
    final result = DiscoveryService.dedupeAndShuffle(input, random: Random(1));

    expect(result, hasLength(DiscoveryService.maximumTracks));
  });

  test('artist matching is exact while allowing explicit featured credits', () {
    expect(DiscoveryService.artistMatches('Queen', 'Queen'), isTrue);
    expect(
      DiscoveryService.artistMatches('Queen feat. David Bowie', 'Queen'),
      isTrue,
    );
    expect(
      DiscoveryService.artistMatches('Queens of the Stone Age', 'Queen'),
      isFalse,
    );
  });

  test(
    'buildFeed keeps own tracks, tolerates one failed seed, and dedupes',
    () async {
      final queries = <String>[];
      final service = DiscoveryService((query, {int limit = 30}) async {
        queries.add(query);
        return switch (query) {
          'Queen' => [
            track('own', artist: 'Queen'),
            track('wrong', artist: 'Queens of the Stone Age'),
          ],
          'rock' => throw Exception('one seed failed'),
          'ambient' => [
            track('own', artist: 'Queen'),
            track('similar', artist: 'Ambient Artist'),
          ],
          _ => const <TrackSummary>[],
        };
      }, random: Random(2));

      final feed = await service.buildFeed(
        artists: const ['Queen'],
        genres: const {'Rock', 'Ambient'},
      );

      expect(queries, containsAll(['Queen', 'rock', 'ambient']));
      expect(feed.map((item) => item.providerTrackId).toSet(), {
        'own',
        'similar',
      });
      expect(feed.any((item) => item.providerTrackId == 'wrong'), isFalse);
    },
  );

  test('buildFeed reports an error only when every search fails', () async {
    final service = DiscoveryService((query, {int limit = 30}) async {
      throw Exception('offline');
    });

    await expectLater(
      service.buildFeed(artists: const ['Artist'], genres: const {'Pop'}),
      throwsA(isA<DiscoveryException>()),
    );
  });

  test('artist preferences store saves and restores cached feed', () async {
    final store = const ArtistPreferencesStore();
    final sampleTracks = [
      track('101', artist: 'Daft Punk'),
      track('102', artist: 'Adele'),
    ];

    await store.saveCachedFeed(sampleTracks);
    final restored = await store.loadCachedFeed();
    final cachedTime = await store.loadCachedFeedTime();

    expect(restored.length, 2);
    expect(restored.first.title, 'Track 101');
    expect(restored.first.artist, 'Daft Punk');
    expect(cachedTime, isNotNull);

    await store.clearCachedFeed();
    final afterClear = await store.loadCachedFeed();
    expect(afterClear, isEmpty);
  });

  test(
    'discovery controller loads cached feed immediately on startup',
    () async {
      final store = const ArtistPreferencesStore();
      await store.save(artists: ['Daft Punk'], genres: {});
      final sampleTracks = [track('101', artist: 'Daft Punk')];
      await store.saveCachedFeed(sampleTracks);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(discoveryControllerProvider.notifier);
      await controller.loadSaved();

      final state = container.read(discoveryControllerProvider);
      expect(state.value, isNotNull);
      expect(state.value!.length, 1);
      expect(state.value!.first.title, 'Track 101');
    },
  );
}
