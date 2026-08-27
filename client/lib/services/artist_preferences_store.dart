import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const discoveryArtistsPreferenceKey = 'discoveryArtists';
const discoveryGenresPreferenceKey = 'discoveryGenres';

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
