import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/models/track.dart';
import 'package:hi_hat/services/lyrics_translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const track = TrackSummary(
    id: 'monochrome:translation-test',
    provider: 'monochrome',
    providerTrackId: 'translation-test',
    title: 'Translation Test',
    artist: 'Artist',
    quality: AudioQuality(),
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rejects an installer built without the shared DeepL key', () async {
    final service = LyricsTranslationService(deeplApiKey: '');

    await expectLater(
      service.translateToEnglish(track, 'Bonjour'),
      throwsA(
        isA<LyricsTranslationException>().having(
          (error) => error.message,
          'message',
          contains('installer is missing'),
        ),
      ),
    );
  });

  test(
    'desktop translation uses the packaged key and caches the result',
    () async {
      var requests = 0;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests += 1;
              expect(
                options.headers['Authorization'],
                'DeepL-Auth-Key packaged-key',
              );
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'translations': [
                      {'text': 'Hello', 'detected_source_language': 'FR'},
                    ],
                  },
                ),
              );
            },
          ),
        );
      final service = LyricsTranslationService(
        dio: dio,
        deeplApiKey: 'packaged-key',
      );

      final first = await service.translateToEnglish(track, 'Bonjour');
      final cached = await service.translateToEnglish(track, 'Bonjour');

      expect(first?.text, 'Hello');
      expect(first?.sourceLanguage, 'fr');
      expect(cached?.text, 'Hello');
      expect(requests, 1);
    },
  );

  test('ignores legacy fallback cache entries after upgrading', () async {
    SharedPreferences.setMockInitialValues({
      'lyrics_translation_en_v1_monochrome:translation-test':
          '{"text":"AUTO is an invalid source language","language":"auto"}',
    });
    var requests = 0;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests += 1;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'translations': [
                    {'text': 'Hello', 'detected_source_language': 'FR'},
                  ],
                },
              ),
            );
          },
        ),
      );

    final result = await LyricsTranslationService(
      dio: dio,
      deeplApiKey: 'packaged-key',
    ).translateToEnglish(track, 'Bonjour');

    expect(result?.text, 'Hello');
    expect(requests, 1);
  });
}
