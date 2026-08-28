import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../services/artist_preferences_store.dart';
import '../../services/discovery_service.dart';

class DiscoveryController
    extends StateNotifier<AsyncValue<List<TrackSummary>>> {
  DiscoveryController(this.ref) : super(const AsyncValue.loading()) {
    unawaited(loadSaved());
  }

  final Ref ref;
  List<String> _artists = const [];
  Set<String> _genres = const {};
  int _generation = 0;
  bool _isRefreshing = false;

  List<String> get artists => _artists;
  Set<String> get genres => _genres;
  bool get hasArtists => _artists.isNotEmpty;
  bool get isRefreshing => _isRefreshing;

  Future<void> loadSaved() async {
    try {
      final store = ref.read(artistPreferencesStoreProvider);
      final preferences = await store.load();
      _artists = preferences.artists;
      _genres = preferences.genres;
      if (_artists.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      // Fast-path: immediately display cached feed if available (0ms startup latency)
      final cachedTracks = await store.loadCachedFeed();
      if (cachedTracks.isNotEmpty) {
        state = AsyncValue.data(cachedTracks);
        final cachedTime = await store.loadCachedFeedTime();
        final isStale = cachedTime == null ||
            DateTime.now().difference(cachedTime) > const Duration(minutes: 20);
        if (isStale) {
          unawaited(_silentRefresh());
        }
        return;
      }

      // If no cached feed exists yet, fetch and display
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setArtists(List<String> artists) =>
      updatePreferences(artists: artists, genres: _genres);

  Future<void> setGenres(Set<String> genres) =>
      updatePreferences(artists: _artists, genres: genres);

  Future<void> updatePreferences({
    required List<String> artists,
    required Set<String> genres,
  }) async {
    final previousArtists = _artists;
    final previousGenres = _genres;
    _artists = _uniqueArtists(artists);
    _genres = genres.map((genre) => genre.trim()).where((genre) {
      return genre.isNotEmpty;
    }).toSet();
    try {
      await ref
          .read(artistPreferencesStoreProvider)
          .save(artists: _artists, genres: _genres);
    } catch (error, stackTrace) {
      _artists = previousArtists;
      _genres = previousGenres;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
    if (_artists.isEmpty) {
      _generation++;
      state = const AsyncValue.data([]);
      await ref.read(artistPreferencesStoreProvider).clearCachedFeed();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_artists.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    final generation = ++_generation;
    state = const AsyncValue.loading();
    try {
      final tracks = await ref
          .read(discoveryServiceProvider)
          .buildFeed(artists: _artists, genres: _genres);
      if (generation == _generation) {
        state = AsyncValue.data(tracks);
        await ref.read(artistPreferencesStoreProvider).saveCachedFeed(tracks);
      }
    } catch (error, stackTrace) {
      if (generation == _generation) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> _silentRefresh() async {
    if (_artists.isEmpty || _isRefreshing) return;
    _isRefreshing = true;
    final generation = ++_generation;
    try {
      final tracks = await ref
          .read(discoveryServiceProvider)
          .buildFeed(artists: _artists, genres: _genres);
      if (generation == _generation) {
        state = AsyncValue.data(tracks);
        await ref.read(artistPreferencesStoreProvider).saveCachedFeed(tracks);
      }
    } catch (error) {
      developer.log('Silent discovery refresh skipped: $error', name: 'HiHat');
    } finally {
      _isRefreshing = false;
    }
  }

  static List<String> _uniqueArtists(List<String> artists) {
    final seen = <String>{};
    return artists
        .map((artist) => artist.trim())
        .where((artist) => artist.isNotEmpty)
        .where((artist) => seen.add(artist.toLowerCase()))
        .toList(growable: false);
  }
}

final discoveryControllerProvider =
    StateNotifierProvider<DiscoveryController, AsyncValue<List<TrackSummary>>>(
      DiscoveryController.new,
    );
