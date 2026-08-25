import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/provider_search_service.dart';

class SearchController extends StateNotifier<AsyncValue<List<TrackSummary>>> {
  SearchController(this.ref) : super(const AsyncValue.data([]));
  final Ref ref;

  Future<void> search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    final localRows = await ref.read(databaseProvider).searchLibrary(clean);
    final local = localRows.map(localTrackSummary).toList(growable: false);
    try {
      final remote = await ref
          .read(providerSearchServiceProvider)
          .search(clean);
      state = AsyncValue.data([...local, ...remote]);
    } catch (error, stackTrace) {
      state = local.isNotEmpty
          ? AsyncValue.data(local)
          : AsyncValue.error(error, stackTrace);
    }
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, AsyncValue<List<TrackSummary>>>(
      SearchController.new,
    );
