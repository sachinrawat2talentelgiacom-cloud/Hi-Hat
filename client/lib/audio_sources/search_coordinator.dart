import 'dart:async';

import 'audio_source_adapter.dart';
import 'candidate_matcher.dart';

enum CoordinatedSearchState {
  searching,
  partialResults,
  resultsReady,
  noResults,
}

class CoordinatedSearchUpdate {
  const CoordinatedSearchUpdate({
    required this.state,
    required this.candidates,
    required this.sourceStates,
  });

  final CoordinatedSearchState state;
  final List<SourceTrackCandidate> candidates;
  final Map<String, String> sourceStates;
}

class SearchCoordinator {
  SearchCoordinator(
    this.adapters, {
    this.overallTimeout = const Duration(seconds: 6),
  });

  final List<AudioSourceAdapter> adapters;
  final Duration overallTimeout;

  Stream<CoordinatedSearchUpdate> search(SearchTrackRequest request) {
    final controller = StreamController<CoordinatedSearchUpdate>();
    final tokens = {
      for (final adapter in adapters) adapter.id: CancellationToken(),
    };
    final states = {for (final adapter in adapters) adapter.id: 'SEARCHING'};
    final candidates = <String, SourceTrackCandidate>{};
    var remaining = adapters.length;
    var closed = false;

    List<SourceTrackCandidate> sorted() {
      final values = candidates.values.toList();
      values.sort(
        (a, b) => CandidateMatcher.score(
          request,
          b,
        ).compareTo(CandidateMatcher.score(request, a)),
      );
      return values;
    }

    Future<void> finish() async {
      if (closed) return;
      closed = true;
      for (final token in tokens.values) {
        token.cancel();
      }
      final values = sorted();
      controller.add(
        CoordinatedSearchUpdate(
          state: values.isEmpty
              ? CoordinatedSearchState.noResults
              : CoordinatedSearchState.resultsReady,
          candidates: values,
          sourceStates: Map.unmodifiable(states),
        ),
      );
      await controller.close();
    }

    controller.add(
      CoordinatedSearchUpdate(
        state: CoordinatedSearchState.searching,
        candidates: const [],
        sourceStates: Map.unmodifiable(states),
      ),
    );

    Timer(overallTimeout, finish);
    for (final adapter in adapters) {
      () async {
        try {
          final results = await adapter
              .search(request, tokens[adapter.id]!)
              .timeout(adapter.searchTimeout);
          if (closed) return;
          for (final candidate in results.where(
            (item) => CandidateMatcher.isPlausible(request, item),
          )) {
            candidates.putIfAbsent(
              CandidateMatcher.logicalKey(candidate),
              () => candidate,
            );
          }
          states[adapter.id] = results.isEmpty ? 'NO_MATCH' : 'SEARCH_COMPLETE';
          controller.add(
            CoordinatedSearchUpdate(
              state: candidates.isEmpty
                  ? CoordinatedSearchState.searching
                  : CoordinatedSearchState.partialResults,
              candidates: sorted(),
              sourceStates: Map.unmodifiable(states),
            ),
          );
        } on TimeoutException {
          states[adapter.id] = 'TIMEOUT';
        } catch (error) {
          states[adapter.id] = 'ERROR:${error.runtimeType}';
        } finally {
          remaining--;
          if (remaining == 0) await finish();
        }
      }();
    }
    if (adapters.isEmpty) finish();
    controller.onCancel = () {
      for (final token in tokens.values) {
        token.cancel();
      }
    };
    return controller.stream;
  }
}
