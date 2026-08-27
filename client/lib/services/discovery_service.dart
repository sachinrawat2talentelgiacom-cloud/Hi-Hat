import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import 'provider_search_service.dart';

typedef DiscoverySearch = Future<List<TrackSummary>> Function(
  String query, {
  int limit,
});

class DiscoveryException implements Exception {
  const DiscoveryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DiscoveryService {
  DiscoveryService(this._search, {Random? random})
    : _random = random ?? Random();

  final DiscoverySearch _search;
  final Random _random;

  static const maximumTracks = 48;
  static const availableGenres = <String>[
    'Pop',
    'Rock',
    'Hip hop',
    'Electronic',
    'Jazz',
    'Lo-fi',
    'Indie',
    'Classical',
    'Metal',
    'Country',
    'Dance',
    'R&B',
    'Ambient',
  ];

  // This is intentionally small and editable. Unknown artists use the user's
  // chosen genres, then the neutral fallback seeds below.
  static const artistGenreSeeds = <String, Set<String>>{
    'adele': {'pop'},
    'arctic monkeys': {'indie', 'rock'},
    'beyonce': {'pop', 'r&b'},
    'billie eilish': {'pop', 'indie'},
    'daft punk': {'electronic', 'dance'},
    'drake': {'hip hop', 'r&b'},
    'dua lipa': {'pop', 'dance'},
    'kendrick lamar': {'hip hop'},
    'lana del rey': {'indie', 'pop'},
    'metallica': {'metal', 'rock'},
    'radiohead': {'indie', 'rock'},
    'taylor swift': {'pop', 'country'},
    'the beatles': {'rock', 'pop'},
    'the weeknd': {'r&b', 'pop'},
  };

  static const fallbackSeeds = <String>{'popular music', 'new music'};

  static Set<String> genreSeedsFor(
    List<String> artists,
    Set<String> selectedGenres,
  ) {
    final seeds = <String>{
      ...selectedGenres.map(_normalize),
      for (final artist in artists) ...?artistGenreSeeds[_normalize(artist)],
    }..removeWhere((seed) => seed.isEmpty);
    return seeds.isEmpty ? fallbackSeeds : seeds;
  }

  static List<TrackSummary> dedupeAndShuffle(
    Iterable<TrackSummary> tracks, {
    Random? random,
    int limit = maximumTracks,
  }) {
    final unique = <String, TrackSummary>{};
    for (final track in tracks) {
      unique.putIfAbsent(track.providerTrackId, () => track);
    }
    final result = unique.values.toList()..shuffle(random ?? Random());
    return result.take(limit).toList(growable: false);
  }

  Future<List<TrackSummary>> buildFeed({
    required List<String> artists,
    required Set<String> genres,
  }) async {
    final cleanArtists = artists
        .map((artist) => artist.trim())
        .where((artist) => artist.isNotEmpty)
        .toList(growable: false);
    final seeds = genreSeedsFor(cleanArtists, genres);
    final ownTracks = <TrackSummary>[];
    final similarTracks = <TrackSummary>[];
    var successfulSearches = 0;

    final artistResults = await Future.wait(
      cleanArtists.map((artist) => _safeSearch(artist)),
    );
    for (var index = 0; index < artistResults.length; index++) {
      final result = artistResults[index];
      if (result.succeeded) successfulSearches++;
      ownTracks.addAll(
        result.tracks.where(
          (track) => artistMatches(track.artist, cleanArtists[index]),
        ),
      );
    }

    final seedResults = await Future.wait(seeds.map(_safeSearch));
    final ownIds = ownTracks.map((track) => track.providerTrackId).toSet();
    for (final result in seedResults) {
      if (result.succeeded) successfulSearches++;
      similarTracks.addAll(
        result.tracks.where((track) => !ownIds.contains(track.providerTrackId)),
      );
    }

    if (successfulSearches == 0) {
      throw const DiscoveryException(
        'Preference-based discovery is temporarily unavailable.',
      );
    }
    return dedupeAndShuffle([...ownTracks, ...similarTracks], random: _random);
  }

  Future<_DiscoverySearchResult> _safeSearch(String query) async {
    try {
      return _DiscoverySearchResult(
        succeeded: true,
        tracks: await _search(query, limit: 18),
      );
    } catch (_) {
      return const _DiscoverySearchResult(succeeded: false, tracks: []);
    }
  }

  static bool artistMatches(String candidate, String selected) {
    final normalizedCandidate = _normalize(candidate);
    final normalizedSelected = _normalize(selected);
    if (normalizedCandidate == normalizedSelected) return true;
    final creditedArtists = normalizedCandidate.split(
      RegExp(r'\s+(?:feat\.?|featuring|with|x)\s+|\s*[,;]\s*'),
    );
    return creditedArtists.any((artist) => artist == normalizedSelected);
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

class _DiscoverySearchResult {
  const _DiscoverySearchResult({required this.succeeded, required this.tracks});

  final bool succeeded;
  final List<TrackSummary> tracks;
}

final discoveryServiceProvider = Provider(
  (ref) => DiscoveryService(ref.read(providerSearchServiceProvider).search),
);
