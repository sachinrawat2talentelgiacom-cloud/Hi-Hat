import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

class LyricLine {
  const LyricLine(this.time, this.text);
  final Duration time;
  final String text;
}

class LyricsResult {
  const LyricsResult({
    required this.plain,
    this.synced = const [],
    this.source = 'LRCLIB',
  });
  final String plain, source;
  final List<LyricLine> synced;
}

class LyricsService {
  LyricsService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://lrclib.net/api',
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
              headers: const {'User-Agent': 'Hi-Hat/1.0 (music player)'},
            ),
          );
  final Dio _dio;
  static const _prefix = 'lyrics_v1_';
  static const _indexKey = 'lyrics_v1_index';
  static const _maximumCachedSongs = 100;

  Future<LyricsResult?> fetch(TrackSummary track) async {
    final key = '$_prefix${track.provider}:${track.providerTrackId}';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached != null) {
      return _decode(jsonDecode(cached) as Map<String, dynamic>);
    }
    try {
      final response = await _dio.get<dynamic>(
        '/get',
        queryParameters: {
          'track_name': track.title,
          'artist_name': track.artist,
          if (track.album != null) 'album_name': track.album,
          if (track.durationSeconds != null)
            'duration': track.durationSeconds!.round(),
        },
      );
      if (response.data is! Map) return null;
      final data = Map<String, dynamic>.from(response.data as Map);
      final plain = (data['plainLyrics'] ?? '').toString().trim();
      final synced = (data['syncedLyrics'] ?? '').toString().trim();
      if (plain.isEmpty && synced.isEmpty) return null;
      final value = {
        'plain': plain.isEmpty ? _stripLrc(synced) : plain,
        'synced': synced,
      };
      await prefs.setString(key, jsonEncode(value));
      final index = prefs.getStringList(_indexKey) ?? <String>[];
      index.remove(key);
      index.add(key);
      while (index.length > _maximumCachedSongs) {
        await prefs.remove(index.removeAt(0));
      }
      await prefs.setStringList(_indexKey, index);
      return _decode(value);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw const LyricsException('Lyrics are temporarily unavailable.');
    } catch (_) {
      throw const LyricsException('Lyrics could not be loaded.');
    }
  }

  static LyricsResult _decode(Map<String, dynamic> json) => LyricsResult(
    plain: (json['plain'] ?? '').toString(),
    synced: _parseLrc((json['synced'] ?? '').toString()),
  );
  static List<LyricLine> _parseLrc(String value) {
    final pattern = RegExp(r'^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$');
    return value
        .split('\n')
        .map(pattern.firstMatch)
        .whereType<RegExpMatch>()
        .map((m) {
          final seconds =
              int.parse(m.group(1)!) * 60 + double.parse(m.group(2)!);
          return LyricLine(
            Duration(milliseconds: (seconds * 1000).round()),
            m.group(3)!,
          );
        })
        .toList();
  }

  static String _stripLrc(String value) =>
      value.replaceAll(RegExp(r'^\[[^\]]+\]\s*', multiLine: true), '').trim();
}

class LyricsException implements Exception {
  const LyricsException(this.message);
  final String message;
}

final lyricsServiceProvider = Provider((ref) => LyricsService());
final lyricsProvider = FutureProvider.family<LyricsResult?, TrackSummary>(
  (ref, track) => ref.read(lyricsServiceProvider).fetch(track),
);
