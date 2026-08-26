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
    'https://monochrome-api.samidy.com',
    'https://api.monochrome.tf',
  ];
  final Dio _dio;
  final Map<String, _CachedSearch> _cache = {};
  final Map<String, DateTime> _unavailableUntil = {};

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
    final artistValue =
        item['artist'] ?? ((item['artists'] as List?)?.firstOrNull);
    final albumValue = item['album'];
    final artist = artistValue is Map ? artistValue['name'] : artistValue;
    final album = albumValue is Map ? albumValue['title'] : albumValue;
    final cover = albumValue is Map ? albumValue['cover'] : null;
    final quality = (item['audioQuality'] ?? '').toString().toUpperCase();
    return TrackSummary(
      id: 'monochrome:${item['id']}',
      provider: 'monochrome',
      providerTrackId: item['id'].toString(),
      title: (item['title'] ?? 'Unknown track').toString(),
      artist: (artist ?? 'Unknown artist').toString(),
      album: album?.toString(),
      artworkUrl: cover == null ? null : '$instance/cover/?id=$cover&size=640',
      durationSeconds: (item['duration'] as num?)?.toDouble(),
      explicit: item['explicit'] == true,
      quality: AudioQuality(
        codec: quality.contains('LOSSLESS') ? 'FLAC' : null,
        lossless: quality.contains('LOSSLESS'),
        label: quality.isEmpty ? null : quality,
      ),
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
