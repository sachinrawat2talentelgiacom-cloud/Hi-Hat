import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';
import 'lyrics_service.dart';

class TranslatedLyrics {
  const TranslatedLyrics({required this.text, required this.sourceLanguage});

  final String text;
  final String sourceLanguage;
}

class LyricsTranslationService {
  LyricsTranslationService({Dio? dio, String? deeplApiKey})
    : _dio = dio ?? Dio(),
      _deeplApiKey =
          deeplApiKey ??
          Platform.environment['HI_HAT_DEEPL_API_KEY'] ??
          const String.fromEnvironment('DEEPL_API_KEY');

  // v2 invalidates responses cached by the short-lived no-key fallback. Those
  // responses could contain provider error text instead of translated lyrics.
  static const _prefix = 'lyrics_translation_en_v2_';
  static const _deeplApiUrl = 'https://api-free.deepl.com/v2/translate';

  final Dio _dio;
  final String _deeplApiKey;

  Future<TranslatedLyrics?> translateToEnglish(
    TrackSummary track,
    String lyrics,
  ) async {
    final key = '$_prefix${track.provider}:${track.providerTrackId}';
    final preferences = await SharedPreferences.getInstance();
    final cached = preferences.getString(key);
    if (cached != null) {
      final value = Map<String, dynamic>.from(jsonDecode(cached) as Map);
      return TranslatedLyrics(
        text: value['text'].toString(),
        sourceLanguage: value['language'].toString(),
      );
    }

    return _translateOnline(lyrics, preferences, key);
  }

  Future<TranslatedLyrics> _translateOnline(
    String lyrics,
    SharedPreferences preferences,
    String cacheKey,
  ) async {
    if (_deeplApiKey.trim().isEmpty) {
      throw const LyricsTranslationException(
        'This installer is missing its shared DeepL configuration. Install a '
        'verified Hi Hat release.',
      );
    }
    final result = await _translateWithDeepL(lyrics);
    await preferences.setString(
      cacheKey,
      jsonEncode({'text': result.text, 'language': result.sourceLanguage}),
    );
    return result;
  }

  Future<TranslatedLyrics> _translateWithDeepL(String lyrics) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _deeplApiUrl,
      options: Options(
        headers: {
          'Authorization': 'DeepL-Auth-Key $_deeplApiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'text': [lyrics],
        'target_lang': 'EN-US',
        'preserve_formatting': true,
      },
    );
    final data = response.data;
    final translations = data?['translations'];
    if (translations is! List || translations.isEmpty) {
      throw const LyricsTranslationException(
        'The translation provider returned an empty response.',
      );
    }
    final translation = Map<String, dynamic>.from(translations.first as Map);
    return TranslatedLyrics(
      text: translation['text'].toString().trim(),
      sourceLanguage: (translation['detected_source_language'] ?? 'unknown')
          .toString()
          .toLowerCase(),
    );
  }
}

class LyricsTranslationException implements Exception {
  const LyricsTranslationException(this.message);
  final String message;
}

final lyricsTranslationServiceProvider = Provider(
  (ref) => LyricsTranslationService(),
);

final englishLyricsProvider =
    FutureProvider.family<TranslatedLyrics?, TrackSummary>((ref, track) async {
      final lyrics = await ref.read(lyricsServiceProvider).fetch(track);
      if (lyrics == null || lyrics.plain.trim().isEmpty) return null;
      return ref
          .read(lyricsTranslationServiceProvider)
          .translateToEnglish(track, lyrics.plain);
    });
