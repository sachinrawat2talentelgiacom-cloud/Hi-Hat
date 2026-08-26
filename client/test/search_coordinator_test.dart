import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/audio_sources/audio_source_adapter.dart';
import 'package:hi_hat/audio_sources/candidate_matcher.dart';
import 'package:hi_hat/audio_sources/search_coordinator.dart';

void main() {
  const request = SearchTrackRequest(
    title: 'Open Song',
    artist: 'Artist',
    query: 'Open Song Artist',
  );

  test('normalizes punctuation and scores exact identity', () {
    const candidate = SourceTrackCandidate(
      source: 'a',
      sourceTrackId: '1',
      title: 'Open Song!',
      artist: 'Artist',
    );
    expect(CandidateMatcher.isPlausible(request, candidate), isTrue);
    expect(CandidateMatcher.score(request, candidate), 80);
  });

  test(
    'emits healthy partial results without waiting for timed-out source',
    () async {
      final coordinator = SearchCoordinator([
        _FakeAdapter(
          'slow',
          const Duration(seconds: 1),
          const Duration(milliseconds: 20),
          const [],
        ),
        _FakeAdapter(
          'fast',
          const Duration(milliseconds: 5),
          const Duration(seconds: 1),
          const [
            SourceTrackCandidate(
              source: 'fast',
              sourceTrackId: '1',
              title: 'Open Song',
              artist: 'Artist',
            ),
          ],
        ),
      ], overallTimeout: const Duration(milliseconds: 100));

      final updates = await coordinator.search(request).toList();
      expect(
        updates.any(
          (update) => update.state == CoordinatedSearchState.partialResults,
        ),
        isTrue,
      );
      expect(updates.last.state, CoordinatedSearchState.resultsReady);
      expect(updates.last.candidates.single.source, 'fast');
      expect(updates.last.sourceStates['slow'], 'TIMEOUT');
    },
  );

  test('deduplicates equivalent candidates across sources', () async {
    final coordinator = SearchCoordinator([
      _FakeAdapter('a', Duration.zero, const Duration(seconds: 1), const [
        SourceTrackCandidate(
          source: 'a',
          sourceTrackId: '1',
          title: 'Open Song',
          artist: 'Artist',
          durationSeconds: 10,
        ),
      ]),
      _FakeAdapter('b', Duration.zero, const Duration(seconds: 1), const [
        SourceTrackCandidate(
          source: 'b',
          sourceTrackId: '2',
          title: 'Open Song',
          artist: 'Artist',
          durationSeconds: 11,
        ),
      ]),
    ]);
    final updates = await coordinator.search(request).toList();
    expect(updates.last.candidates, hasLength(1));
  });
}

class _FakeAdapter implements AudioSourceAdapter {
  _FakeAdapter(this.id, this.delay, this.searchTimeout, this.results);
  @override
  final String id;
  final Duration delay;
  @override
  final Duration searchTimeout;
  final List<SourceTrackCandidate> results;
  @override
  Future<SourceHealth> healthCheck() async =>
      const SourceHealth(SourceHealthStatus.healthy);
  @override
  Future<List<SourceTrackCandidate>> search(
    SearchTrackRequest request,
    CancellationToken token,
  ) async {
    await Future<void>.delayed(delay);
    token.throwIfCancelled();
    return results;
  }

  @override
  Future<ResolvedAudioCandidate?> resolveFlac(
    SourceTrackCandidate candidate,
    CancellationToken token,
  ) async => null;
}
