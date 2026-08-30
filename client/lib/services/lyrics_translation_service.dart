import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
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

  static const _prefix = 'lyrics_translation_en_v1_';
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

    if (!Platform.isAndroid && !Platform.isIOS) {
      return _translateOnDesktop(lyrics, preferences, key);
    }

    final identifier = LanguageIdentifier(confidenceThreshold: 0.45);
    String languageCode;
    try {
      languageCode = await identifier.identifyLanguage(lyrics);
    } finally {
      identifier.close();
    }
    if (languageCode == 'en') return null;
    final sourceLanguage = BCP47Code.fromRawValue(languageCode);
    if (sourceLanguage == null || languageCode == 'und') {
      throw const LyricsTranslationException(
        'The language in these lyrics could not be identified.',
      );
    }

    final manager = OnDeviceTranslatorModelManager();
    await manager.downloadModel(sourceLanguage.bcpCode, isWifiRequired: false);
    await manager.downloadModel(
      TranslateLanguage.english.bcpCode,
      isWifiRequired: false,
    );
    final translator = OnDeviceTranslator(
      sourceLanguage: sourceLanguage,
      targetLanguage: TranslateLanguage.english,
    );
    try {
      final translated = await translator.translateText(lyrics);
      final result = TranslatedLyrics(
        text: translated.trim(),
        sourceLanguage: languageCode,
      );
      await preferences.setString(
        key,
        jsonEncode({'text': result.text, 'language': result.sourceLanguage}),
      );
      return result;
    } catch (_) {
      throw const LyricsTranslationException(
        'The English translation could not be created. Check your connection and try again.',
      );
    } finally {
      translator.close();
    }
  }

  Future<TranslatedLyrics> _translateOnDesktop(
    String lyrics,
    SharedPreferences preferences,
    String cacheKey,
  ) async {
    if (_deeplApiKey.trim().isEmpty) {
      throw const LyricsTranslationException(
        'PC translation needs a DeepL API key in the Hi Hat launcher configuration.',
      );
    }
    try {
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
      final result = TranslatedLyrics(
        text: translation['text'].toString().trim(),
        sourceLanguage: (translation['detected_source_language'] ?? 'unknown')
            .toString()
            .toLowerCase(),
      );
      await preferences.setString(
        cacheKey,
        jsonEncode({'text': result.text, 'language': result.sourceLanguage}),
      );
      return result;
    } on DioException catch (error) {
      final unauthorized = error.response?.statusCode == 403;
      throw LyricsTranslationException(
        unauthorized ? 'DeepL rejected the configured API key.' : 'Online translation is unavailable. Check your connection and try again.',
      );
    }
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
