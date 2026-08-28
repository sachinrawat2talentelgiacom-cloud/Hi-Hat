import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hi_hat/models/album.dart';
import 'package:hi_hat/models/track.dart';
import 'package:hi_hat/services/lyrics_service.dart';
import 'package:hi_hat/services/provider_search_service.dart';

class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object value, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(value),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
const song = TrackSummary(
  id: 'x:1',
  provider: 'x',
  providerTrackId: '1',
  title: 'A Song',
  artist: 'An Artist',
  album: 'An Album',
  durationSeconds: 120,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'lyrics parses synchronized lines and caches successful responses',
    () async {
      final adapter = StubAdapter(
        (_) => jsonBody({
          'plainLyrics': 'First\nSecond',
          'syncedLyrics': '[00:01.00] First\n[00:05.50] Second',
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = LyricsService(dio: dio);
      final first = await service.fetch(song);
      final second = await service.fetch(song);
      expect(first!.synced, hasLength(2));
      expect(first.synced.last.time, const Duration(milliseconds: 5500));
      expect(second!.plain, 'First\nSecond');
      expect(adapter.calls, 1);
    },
  );
  test('lyrics reports unavailable on 404', () async {
    final dio = Dio()
      ..httpClientAdapter = StubAdapter((_) => jsonBody({}, status: 404));
    expect(await LyricsService(dio: dio).fetch(song), isNull);
  });
  test('album search maps partial provider results and loads tracks', () async {
    final adapter = StubAdapter((request) {
      if (request.path.endsWith('/search/')) {
        return jsonBody({
          'data': {
            'albums': {
              'items': [
                {
                  'id': 9,
                  'title': 'Record',
                  'artist': {'name': 'Singer'},
                  'cover': 'aa-bb',
                  'releaseDate': '2024-01-01',
                },
              ],
            },
          },
        });
      }
      return jsonBody({
        'data': {
          'tracks': {
            'items': [
              {
                'id': 1,
                'title': 'Track',
                'artist': {'name': 'Singer'},
                'album': {'title': 'Record'},
                'duration': 123,
              },
            ],
          },
        },
      });
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final service = ProviderSearchService(dio: dio);
    final albums = await service.searchAlbums('record');
    expect(albums.single, isA<AlbumSummary>());
    expect(albums.single.title, 'Record');
    final details = await service.albumDetails(albums.single);
    expect(details.tracks.single.title, 'Track');
  });
}
