import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

class CustomPlaylist {
  const CustomPlaylist({
    required this.id,
    required this.name,
    this.tracks = const [],
  });

  final String id;
  final String name;
  final List<TrackSummary> tracks;

  CustomPlaylist copyWith({String? name, List<TrackSummary>? tracks}) =>
      CustomPlaylist(
        id: id,
        name: name ?? this.name,
        tracks: tracks ?? this.tracks,
      );

  factory CustomPlaylist.fromJson(Map<String, dynamic> json) => CustomPlaylist(
    id: json['id'].toString(),
    name: json['name'].toString(),
    tracks: (json['tracks'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => TrackSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tracks': tracks.map((track) => track.toJson()).toList(),
  };
}

class PlaylistState {
  const PlaylistState({
    this.loading = true,
    this.playlists = const [],
    this.error,
  });
  final bool loading;
  final List<CustomPlaylist> playlists;
  final String? error;
}

class PlaylistController extends StateNotifier<PlaylistState> {
  PlaylistController() : super(const PlaylistState()) {
    _load();
  }
  static const _key = 'custom_playlists_v2';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          prefs.getString(_key) ?? prefs.getString('custom_playlists_v1');
      final decoded = raw == null ? const <dynamic>[] : jsonDecode(raw) as List;
      state = PlaylistState(
        loading: false,
        playlists: decoded
            .whereType<Map>()
            .map(
              (value) =>
                  CustomPlaylist.fromJson(Map<String, dynamic>.from(value)),
            )
            .toList(),
      );
      if (raw != null) await _save();
    } catch (_) {
      state = const PlaylistState(
        loading: false,
        error: 'Playlists could not be restored.',
      );
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.playlists.map((p) => p.toJson()).toList()),
    );
  }

  String? validateName(String value, {String? exceptId}) {
    final name = value.trim();
    if (name.isEmpty) return 'Enter a playlist name.';
    if (state.playlists.any(
      (p) => p.id != exceptId && p.name.toLowerCase() == name.toLowerCase(),
    )) {
      return 'A playlist with that name already exists.';
    }
    return null;
  }

  Future<String?> create(String name) async {
    final error = validateName(name);
    if (error != null) return error;
    final playlist = CustomPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    state = PlaylistState(
      loading: false,
      playlists: [...state.playlists, playlist],
    );
    await _save();
    return null;
  }

  Future<String?> rename(String id, String name) async {
    final error = validateName(name, exceptId: id);
    if (error != null) return error;
    state = PlaylistState(
      loading: false,
      playlists: [
        for (final playlist in state.playlists)
          if (playlist.id == id)
            playlist.copyWith(name: name.trim())
          else
            playlist,
      ],
    );
    await _save();
    return null;
  }

  Future<void> delete(String id) async {
    state = PlaylistState(
      loading: false,
      playlists: state.playlists.where((p) => p.id != id).toList(),
    );
    await _save();
  }

  Future<void> addTrack(String id, TrackSummary track) async {
    state = PlaylistState(
      loading: false,
      playlists: [
        for (final playlist in state.playlists)
          if (playlist.id == id)
            playlist.copyWith(tracks: [...playlist.tracks, track])
          else
            playlist,
      ],
    );
    await _save();
  }

  Future<void> removeTrack(String id, int index) async {
    state = PlaylistState(
      loading: false,
      playlists: [
        for (final playlist in state.playlists)
          if (playlist.id == id)
            playlist.copyWith(tracks: [...playlist.tracks]..removeAt(index))
          else
            playlist,
      ],
    );
    await _save();
  }

  Future<void> reorder(String id, int oldIndex, int newIndex) async {
    state = PlaylistState(
      loading: false,
      playlists: [
        for (final playlist in state.playlists)
          if (playlist.id == id)
            playlist.copyWith(
              tracks: _reordered(playlist.tracks, oldIndex, newIndex),
            )
          else
            playlist,
      ],
    );
    await _save();
  }

  static List<TrackSummary> _reordered(
    List<TrackSummary> source,
    int oldIndex,
    int newIndex,
  ) {
    final result = [...source];
    final value = result.removeAt(oldIndex);
    result.insert(newIndex, value);
    return result;
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistController, PlaylistState>(
      (ref) => PlaylistController(),
    );
