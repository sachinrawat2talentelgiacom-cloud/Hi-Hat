import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hi_hat/models/track.dart';
import 'package:hi_hat/services/audio_engine.dart';
import 'package:hi_hat/services/provider_search_service.dart';

TrackSummary item(String id) => TrackSummary(
  id: 'local:$id',
  provider: 'local',
  providerTrackId: id,
  title: 'Song $id',
  artist: 'Artist',
  localPath: '$id.flac',
);

TrackSummary relatedItem(
  String id, {
  required String artist,
  String? genre,
  String? album,
}) => TrackSummary(
  id: 'catalog:$id',
  provider: 'catalog',
  providerTrackId: id,
  title: 'Song $id',
  artist: artist,
  genre: genre,
  album: album,
  localPath: '$id.flac',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('queue accepts duplicates, reorders, removes and clears', () async {
    final engine = AudioEngine(ProviderSearchService(), player: FakePlayer());
    await Future<void>.delayed(Duration.zero);
    await engine.addToQueue(item('1'));
    await engine.addToQueue(item('1'));
    await engine.addToQueue(item('2'));
    expect(engine.state.queue.map((e) => e.providerTrackId), ['1', '1', '2']);
    await engine.reorderQueue(2, 0);
    expect(engine.state.queue.first.providerTrackId, '2');
    await engine.removeAt(1);
    expect(engine.state.queue, hasLength(2));
    await engine.clearQueue();
    expect(engine.state.queue, isEmpty);
    engine.dispose();
  });

  test('volume mute shuffle repeat and queue survive restoration', () async {
    final engine = AudioEngine(ProviderSearchService(), player: FakePlayer());
    await Future<void>.delayed(Duration.zero);
    await engine.addToQueue(item('1'));
    await engine.setVolume(.35);
    await engine.toggleMute();
    expect(engine.state.muted, isTrue);
    await engine.toggleMute();
    expect(engine.state.volume, closeTo(.35, .001));
    await engine.toggleShuffle();
    await engine.cycleRepeat();
    final restored = AudioEngine(ProviderSearchService(), player: FakePlayer());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(restored.state.queue, hasLength(1));
    expect(restored.state.volume, closeTo(.35, .001));
    expect(restored.state.shuffle, isTrue);
    expect(restored.state.repeatMode, PlaybackRepeatMode.queue);
    engine.dispose();
    restored.dispose();
  });

  test(
    'starting a song replaces stale history with a fresh related queue',
    () async {
      final engine = AudioEngine(RelatedSearch(), player: FakePlayer());
      await Future<void>.delayed(Duration.zero);
      await engine.addToQueue(item('stale-unrelated-history'));
      await engine.playLocal(item('seed'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(engine.state.relatedAutoplay, isTrue);
      expect(engine.state.queue.map((track) => track.providerTrackId), [
        'seed',
        'related-1',
        'related-2',
      ]);
      engine.dispose();
    },
  );

  test('related queue ranks same artist, then matching genre', () async {
    final engine = AudioEngine(AffinitySearch(), player: FakePlayer());
    await Future<void>.delayed(Duration.zero);
    await engine.playLocal(
      relatedItem('seed', artist: 'Mariya Takeuchi', genre: 'City Pop'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(engine.state.queue.map((track) => track.providerTrackId), [
      'seed',
      'same-artist',
      'same-genre',
    ]);
    expect(
      engine.state.queue.map((track) => track.providerTrackId),
      isNot(contains('unrelated')),
    );
    engine.dispose();
  });
}

class RelatedSearch extends ProviderSearchService {
  @override
  Future<List<TrackSummary>> search(String query, {int limit = 30}) async => [
    item('seed'),
    item('related-1'),
    item('related-2'),
    relatedItem('unrelated', artist: 'Different Artist'),
  ];
}

class AffinitySearch extends ProviderSearchService {
  @override
  Future<List<TrackSummary>> search(String query, {int limit = 30}) async {
    if (query.toLowerCase() == 'mariya takeuchi') {
      return [
        relatedItem('same-artist', artist: 'Mariya Takeuchi'),
        relatedItem('unrelated', artist: 'Different Artist'),
      ];
    }
    if (query.toLowerCase() == 'city pop') {
      return [
        relatedItem(
          'same-genre',
          artist: 'Tatsuro Yamashita',
          genre: 'City Pop',
        ),
        relatedItem('wrong-genre', artist: 'Rock Band', genre: 'Rock'),
      ];
    }
    return [];
  }
}

class FakePlayer implements AudioPlayerAdapter {
  @override
  final playingStream = const Stream<bool>.empty();
  @override
  final positionStream = const Stream<Duration>.empty();
  @override
  final durationStream = const Stream<Duration>.empty();
  @override
  final completedStream = const Stream<bool>.empty();
  @override
  final errorStream = const Stream<String>.empty();
  @override
  Future<void> dispose() async {}
  @override
  Future<void> open(String path) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> playOrPause() async {}
  @override
  Future<void> seek(Duration value) async {}
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<void> stop() async {}
}
