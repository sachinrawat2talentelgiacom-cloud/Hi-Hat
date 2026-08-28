import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

const discoveryArtistsPreferenceKey = 'discoveryArtists';
const discoveryGenresPreferenceKey = 'discoveryGenres';
const discoveryFeedCacheKey = 'discoveryCachedFeed_v1';
const discoveryFeedCacheTimeKey = 'discoveryCachedFeedTime_v1';

class ArtistPreferences {
  const ArtistPreferences({
    this.artists = const <String>[],
    this.genres = const <String>{},
  });

  final List<String> artists;
  final Set<String> genres;
}

class ArtistPreferencesStore {
  const ArtistPreferencesStore();

  Future<ArtistPreferences> load() async {
    final preferences = await SharedPreferences.getInstance();
    return ArtistPreferences(
      artists: _clean(preferences.getStringList(discoveryArtistsPreferenceKey)),
      genres: _clean(preferences.getStringList(discoveryGenresPreferenceKey))
          .toSet(),
    );
  }

  Future<void> save({
    required List<String> artists,
    required Set<String> genres,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      discoveryArtistsPreferenceKey,
      _clean(artists),
    );
    await preferences.setStringList(
      discoveryGenresPreferenceKey,
      _clean(genres.toList())..sort(),
    );
  }

  Future<List<TrackSummary>> loadCachedFeed() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(discoveryFeedCacheKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => TrackSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<DateTime?> loadCachedFeedTime() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final millis = preferences.getInt(discoveryFeedCacheTimeKey);
      return millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCachedFeed(List<TrackSummary> tracks) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(tracks.map((t) => t.toJson()).toList());
      await preferences.setString(discoveryFeedCacheKey, jsonStr);
      await preferences.setInt(
        discoveryFeedCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> clearCachedFeed() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(discoveryFeedCacheKey);
      await preferences.remove(discoveryFeedCacheTimeKey);
    } catch (_) {}
  }

  static List<String> _clean(List<String>? values) {
    final seen = <String>{};
    return (values ?? const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .where((value) => seen.add(value.toLowerCase()))
        .toList(growable: false);
  }
}

final artistPreferencesStoreProvider = Provider(
  (ref) => const ArtistPreferencesStore(),
);
