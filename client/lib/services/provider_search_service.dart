import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';

class ProviderSearchException implements Exception {
  const ProviderSearchException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ProviderSearchService {
  ProviderSearchService()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          headers: const {'User-Agent': 'Hi-Hat/1.0'},
        ),
      );

  static const instances = <String>[
    // Monochrome's current web client uses this v2.10 worker as its default
    // catalog API. Keep the older official hosts as failovers because their
    // availability changes independently.
    'https://lol.samidy.workers.dev',
    'https://monochrome-api.samidy.com',
    'https://api.monochrome.tf',
  ];
  static const catalogSearchEndpoints = <String>[
    'https://api.tidal.com/v1/search/tracks',
    'https://tidal-proxy.monochrome.tf/api/v1/search/tracks',
  ];
  // Public browser application credentials used by Monochrome's open-source
  // HiFiClient for catalog metadata. This is an app token, not a user token.
  static const _catalogClientId = 'txNoH4kkV41MfH25';
  static const _catalogClientSecret =
      'dQjy0MinCEvxi1O4UmxvxWnDjt4cgHBPw8ll6nYBk98=';
  final Dio _dio;
  final Map<String, _CachedSearch> _cache = {};
  final Map<String, DateTime> _unavailableUntil = {};
  String? _catalogToken;
  DateTime? _catalogTokenExpiresAt;
  Future<String>? _catalogTokenRequest;

  static const cacheTtl = Duration(minutes: 7);
  static const providerCooldown = Duration(seconds: 45);

  Future<List<TrackSummary>> search(String query, {int limit = 30}) async {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return const [];
    final cached = _cache[normalized];
    if (cached != null &&
        DateTime.now().difference(cached.storedAt) < cacheTtl) {
      developer.log('search_latency_ms=0 cache_hit=true', name: 'HiHat');
      return cached.results.take(limit).toList(growable: false);
    }

    final stopwatch = Stopwatch()..start();
    Object? lastError;
    try {
      final results = await _searchCatalog(normalized, limit: limit);
      _cache[normalized] = _CachedSearch(DateTime.now(), results);
      developer.log(
        'search_latency_ms=${stopwatch.elapsedMilliseconds} source=tidal_catalog',
        name: 'HiHat',
      );
      return results;
    } catch (error) {
      lastError = error;
      developer.log('catalog_search_failed error=$error', name: 'HiHat');
    }
    for (final instance in instances) {
      final unavailableUntil = _unavailableUntil[instance];
      if (unavailableUntil != null &&
          unavailableUntil.isAfter(DateTime.now())) {
        continue;
      }
      try {
        final response = await _dio.get<dynamic>(
          '$instance/search/',
          queryParameters: {'s': normalized},
        );
        final items = _trackItems(response.data);
        final results = items
            .take(limit)
            .map((item) => _mapTrack(item, instance))
            .toList(growable: false);
        _cache[normalized] = _CachedSearch(DateTime.now(), results);
        _unavailableUntil.remove(instance);
        developer.log(
          'search_latency_ms=${stopwatch.elapsedMilliseconds} cache_hit=false',
          name: 'HiHat',
        );
        return results;
      } catch (error) {
        lastError = error;
        _unavailableUntil[instance] = DateTime.now().add(providerCooldown);
      }
    }
    throw ProviderSearchException(
      lastError == null
          ? 'No music provider is configured.'
          : 'Music search is temporarily unavailable.',
    );
  }

  Future<List<TrackSummary>> _searchCatalog(
    String query, {
    required int limit,
  }) async {
    Object? lastError;
    for (final endpoint in catalogSearchEndpoints) {
      try {
        var token = await _catalogAppToken();
        Response<dynamic> response;
        try {
          response = await _dio.get<dynamic>(
            endpoint,
            queryParameters: {
              'countryCode': 'US',
              'query': query,
              'limit': limit,
              'offset': 0,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } on DioException catch (error) {
          if (error.response?.statusCode != 401) rethrow;
          _catalogToken = null;
          _catalogTokenExpiresAt = null;
          token = await _catalogAppToken();
          response = await _dio.get<dynamic>(
            endpoint,
            queryParameters: {
              'countryCode': 'US',
              'query': query,
              'limit': limit,
              'offset': 0,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        }
        final payload = response.data;
        if (payload is! Map || payload['items'] is! List) {
          throw const ProviderSearchException(
            'The catalog returned an unsupported search response.',
          );
        }
        return _maps(payload['items'])
            .take(limit)
            .map((item) => _mapTrack(item, endpoint))
            .toList(growable: false);
      } catch (error) {
        lastError = error;
      }
    }
    throw ProviderSearchException(
      'Direct catalog search failed: ${lastError ?? 'unknown error'}',
    );
  }

  Future<String> _catalogAppToken() async {
    final now = DateTime.now();
    final cached = _catalogToken;
    if (cached != null && (_catalogTokenExpiresAt?.isAfter(now) ?? false)) {
      return cached;
    }
    final request = _catalogTokenRequest ??= _requestCatalogAppToken(now);
    try {
      return await request;
    } finally {
      if (identical(_catalogTokenRequest, request)) {
        _catalogTokenRequest = null;
      }
    }
  }

  Future<String> _requestCatalogAppToken(DateTime requestedAt) async {
    final basic = base64Encode(
      utf8.encode('$_catalogClientId:$_catalogClientSecret'),
    );
    final response = await _dio.post<dynamic>(
      'https://auth.tidal.com/v1/oauth2/token',
      data: {
        'client_id': _catalogClientId,
        'client_secret': _catalogClientSecret,
        'grant_type': 'client_credentials',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Authorization': 'Basic $basic'},
      ),
    );
    final data = response.data;
    if (data is! Map || data['access_token'] == null) {
      throw const ProviderSearchException(
        'The catalog did not issue an application token.',
      );
    }
    final token = data['access_token'].toString();
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    _catalogToken = token;
    _catalogTokenExpiresAt = requestedAt.add(
      Duration(seconds: (expiresIn - 60).clamp(60, 86400)),
    );
    return token;
  }

  static String _normalize(String query) =>
      query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static List<Map<String, dynamic>> _trackItems(dynamic payload) {
    if (payload is Map) {
      final data = payload['data'];
      if (data is Map && data['items'] is List) {
        return _maps(data['items']);
      }
    }
    final tracks = _findTracks(payload);
    if (tracks == null) {
      throw const ProviderSearchException(
        'The provider returned an unsupported search response.',
      );
    }
    return _maps(tracks['items']);
  }

  static Map<dynamic, dynamic>? _findTracks(dynamic value) {
    if (value is Map) {
      final direct = value['tracks'];
      if (direct is Map && direct['items'] is List) return direct;
      for (final child in value.values) {
        final found = _findTracks(child);
        if (found != null) return found;
      }
    } else if (value is List) {
      for (final child in value) {
        final found = _findTracks(child);
        if (found != null) return found;
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> _maps(dynamic values) => (values as List)
      .whereType<Map>()
      .map(
        (value) => Map<String, dynamic>.from(
          value['item'] is Map ? value['item'] as Map : value,
        ),
      )
      .toList(growable: false);

  static TrackSummary _mapTrack(Map<String, dynamic> item, String instance) {
    final albumValue = item['album'];
    final album = albumValue is Map ? albumValue['title'] : albumValue;
    final vibrantColor = albumValue is Map
        ? albumValue['vibrantColor']?.toString()
        : null;
    final artist = _extractArtist(item);
    final artworkUrl = _resolveArtworkUrl(item, instance);
    final year = _extractYear(item);
    final key = _extractKey(item);
    final quality = _extractQuality(item);

    return TrackSummary(
      id: 'monochrome:${item['id']}',
      provider: 'monochrome',
      providerTrackId: item['id'].toString(),
      title: (item['title'] ?? 'Unknown track').toString(),
      artist: artist,
      album: album?.toString(),
      artworkUrl: artworkUrl,
      durationSeconds: (item['duration'] as num?)?.toDouble(),
      explicit: item['explicit'] == true,
      quality: quality,
      year: year,
      trackNumber: (item['trackNumber'] as num?)?.toInt(),
      discNumber: (item['volumeNumber'] as num? ?? item['discNumber'] as num?)
          ?.toInt(),
      bpm: (item['bpm'] as num?)?.round(),
      key: key,
      isrc: item['isrc']?.toString(),
      copyright: item['copyright']?.toString(),
      replayGain: (item['replayGain'] as num?)?.toDouble(),
      peak: (item['peak'] as num?)?.toDouble(),
      version: item['version']?.toString(),
      vibrantColor: vibrantColor,
    );
  }

  static String _extractArtist(Map<String, dynamic> item) {
    if (item['artists'] is List && (item['artists'] as List).isNotEmpty) {
      final names = (item['artists'] as List)
          .map((a) => a is Map ? a['name']?.toString() : a?.toString())
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names.join(', ');
    }
    final artistValue = item['artist'];
    if (artistValue is Map) {
      return artistValue['name']?.toString() ?? 'Unknown artist';
    }
    if (artistValue != null && artistValue.toString().trim().isNotEmpty) {
      return artistValue.toString().trim();
    }
    return 'Unknown artist';
  }

  static String? _resolveArtworkUrl(
    Map<String, dynamic> item,
    String instance,
  ) {
    final albumValue = item['album'];
    final cover =
        (albumValue is Map ? albumValue['cover'] : null) ??
        item['cover'] ??
        item['picture'] ??
        (item['artist'] is Map ? item['artist']['picture'] : null);
    if (cover == null) return null;
    final coverStr = cover.toString().trim();
    if (coverStr.isEmpty) return null;
    if (coverStr.startsWith('http://') || coverStr.startsWith('https://')) {
      return coverStr;
    }
    final cleanUuid = coverStr.replaceAll('-', '/');
    return 'https://resources.tidal.com/images/$cleanUuid/640x640.jpg';
  }

  static String? _extractYear(Map<String, dynamic> item) {
    if (item['year'] != null && item['year'].toString().trim().isNotEmpty) {
      return item['year'].toString().trim();
    }
    if (item['releaseDate'] != null) {
      final match = RegExp(r'\b(19\d{2}|20\d{2})\b')
          .firstMatch(item['releaseDate'].toString());
      if (match != null) return match.group(1);
    }
    if (item['streamStartDate'] != null) {
      final match = RegExp(r'\b(19\d{2}|20\d{2})\b')
          .firstMatch(item['streamStartDate'].toString());
      if (match != null) return match.group(1);
    }
    if (item['copyright'] != null) {
      final match = RegExp(r'\b(19\d{2}|20\d{2})\b')
          .firstMatch(item['copyright'].toString());
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _extractKey(Map<String, dynamic> item) {
    final key = item['key']?.toString();
    final scale = item['keyScale']?.toString();
    if (key == null || key.isEmpty) return null;
    if (scale != null && scale.isNotEmpty) {
      final titleScale = scale.length > 1
          ? '${scale[0].toUpperCase()}${scale.substring(1).toLowerCase()}'
          : scale;
      return '$key $titleScale';
    }
    return key;
  }

  static AudioQuality _extractQuality(Map<String, dynamic> item) {
    final qualityStr = (item['audioQuality'] ?? '').toString().toUpperCase();
    final modes = item['audioModes'] is List
        ? (item['audioModes'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final isLossless =
        qualityStr.contains('LOSSLESS') || qualityStr.contains('HI_RES');
    return AudioQuality(
      codec: isLossless ? 'FLAC' : null,
      lossless: isLossless,
      label: qualityStr.isEmpty ? null : qualityStr,
      audioModes: modes,
    );
  }
}

class _CachedSearch {
  const _CachedSearch(this.storedAt, this.results);
  final DateTime storedAt;
  final List<TrackSummary> results;
}

final providerSearchServiceProvider = Provider(
  (ref) => ProviderSearchService(),
);
