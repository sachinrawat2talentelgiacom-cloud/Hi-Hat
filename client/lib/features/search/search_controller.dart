import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/provider_search_service.dart';

class SearchController extends StateNotifier<AsyncValue<List<TrackSummary>>> {
  SearchController(this.ref) : super(const AsyncValue.data([]));
  final Ref ref;
  int _requestGeneration = 0;
  static const searchTimeout = Duration(seconds: 10);
  static const maxSearchAttempts = 3;

  Future<void> search(String query) async {
    final generation = ++_requestGeneration;
    final clean = query.trim();
    if (clean.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    final localRows = await ref.read(databaseProvider).searchLibrary(clean);
    if (generation != _requestGeneration) return;
    final local = localRows.map(localTrackSummary).toList(growable: false);
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 1; attempt <= maxSearchAttempts; attempt++) {
      try {
        developer.log(
          'SEARCH_REQUEST_SENT request_id=$generation attempt=$attempt',
          name: 'HiHat',
        );
        final remote = await ref
            .read(providerSearchServiceProvider)
            .search(clean)
            .timeout(
              searchTimeout,
              onTimeout: () => throw const ProviderSearchException(
                'Search source did not respond before the deadline.',
              ),
            );
        if (generation != _requestGeneration) return;
        final localProviderIds = local
            .map((track) => '${track.provider}:${track.providerTrackId}')
            .toSet();
        state = AsyncValue.data([
          ...local,
          ...remote.where(
            (track) => !localProviderIds.contains(
              '${track.provider}:${track.providerTrackId}',
            ),
          ),
        ]);
        developer.log(
          'SEARCH_RESULTS_READY request_id=$generation attempt=$attempt',
          name: 'HiHat',
        );
        return;
      } catch (error, stackTrace) {
        if (generation != _requestGeneration) return;
        lastError = error;
        lastStackTrace = stackTrace;
        developer.log(
          'SEARCH_ATTEMPT_FAILED request_id=$generation attempt=$attempt error=$error',
          name: 'HiHat',
        );
        if (attempt < maxSearchAttempts) {
          await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));
          if (generation != _requestGeneration) return;
        }
      }
    }
    state = local.isNotEmpty
        ? AsyncValue.data(local)
        : AsyncValue.error(
            lastError ?? const ProviderSearchException('Search failed.'),
            lastStackTrace ?? StackTrace.current,
          );
  }

  void cancel() {
    _requestGeneration++;
    state = const AsyncValue.data([]);
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, AsyncValue<List<TrackSummary>>>(
      SearchController.new,
    );
