import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import 'backend_config.dart';

class HiHatApi {
  HiHatApi(this.config)
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Authorization': 'Bearer ${config.token}'},
        ),
      );

  final BackendConfig config;
  final Dio _dio;

  Future<List<TrackSummary>> search(String query) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/search',
      queryParameters: {'q': query, 'limit': 30},
    );
    return (response.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TrackSummary.fromJson)
        .toList(growable: false);
  }

  Future<void> resetBrowserSession() async {
    await _dio.post<void>('/v1/providers/browser/reset-session');
  }

  Future<void> showBrowserAuthorization() async {
    await _dio.post<void>('/v1/providers/browser/show-auth');
  }

  String artworkUrl(String relative) => '${config.baseUrl}$relative';
  Map<String, String> get headers => {
    'Authorization': 'Bearer ${config.token}',
  };
}

final apiProvider = Provider<HiHatApi>(
  (ref) => HiHatApi(ref.watch(backendConfigProvider)),
);
