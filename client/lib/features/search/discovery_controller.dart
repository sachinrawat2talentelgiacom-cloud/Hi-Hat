import 'dart:async';

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

  List<String> get artists => _artists;
  Set<String> get genres => _genres;
  bool get hasArtists => _artists.isNotEmpty;

  Future<void> loadSaved() async {
    try {
      final preferences = await ref.read(artistPreferencesStoreProvider).load();
      _artists = preferences.artists;
      _genres = preferences.genres;
      if (_artists.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
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
      if (generation == _generation) state = AsyncValue.data(tracks);
    } catch (error, stackTrace) {
      if (generation == _generation) {
        state = AsyncValue.error(error, stackTrace);
      }
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
