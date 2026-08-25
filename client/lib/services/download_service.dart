import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/app_database.dart';
import '../models/track.dart';
import 'backend_config.dart';
import 'library_service.dart';

class TransferState {
  const TransferState({
    this.trackId,
    this.phase,
    this.progress = 0,
    this.error,
  });
  final String? trackId;
  final String? phase;
  final double progress;
  final String? error;
}

class DownloadService extends StateNotifier<TransferState> {
  DownloadService(this.ref) : super(const TransferState());
  final Ref ref;

  Future<TrackSummary?> acquire(TrackSummary track) async {
    final database = ref.read(databaseProvider);
    final existing = await database.findByProviderId(track.providerTrackId);
    if (existing != null && await File(existing.localPath).exists()) {
      return track.copyWith(localPath: existing.localPath);
    }

    final config = ref.read(backendConfigProvider);
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        headers: {'Authorization': 'Bearer ${config.token}'},
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(minutes: 30),
      ),
    );
    try {
      state = TransferState(trackId: track.id, phase: 'QUEUED');
      final created = await dio.post<Map<String, dynamic>>(
        '/v1/downloads',
        data: {
          'provider': track.provider,
          'provider_track_id': track.providerTrackId,
          'preferred_quality': 'best_lossless',
        },
      );
      final jobId = created.data!['id'] as String;
      Map<String, dynamic> job = created.data!;
      while (job['status'] != 'READY') {
        if (job['status'] == 'FAILED' || job['status'] == 'CANCELLED') {
          throw StateError(
            job['error_message'] as String? ??
                'The download failed. Try again.',
          );
        }
        state = TransferState(
          trackId: track.id,
          phase: job['status'] as String?,
          progress: (job['progress'] as num?)?.toDouble() ?? 0,
        );
        await Future<void>.delayed(const Duration(milliseconds: 750));
        job = (await dio.get<Map<String, dynamic>>('/v1/downloads/$jobId'))
            .data!;
      }

      final root = await getApplicationDocumentsDirectory();
      final folder = Directory(
        p.join(
          root.path,
          'Music',
          _safe(track.artist),
          _safe(track.album ?? 'Singles'),
        ),
      );
      await folder.create(recursive: true);
      final finalPath = p.join(folder.path, '${_safe(track.title)}.flac');
      final partPath = '$finalPath.part';
      await dio.download(
        '/v1/downloads/$jobId/file',
        partPath,
        deleteOnError: false,
        onReceiveProgress: (received, total) {
          state = TransferState(
            trackId: track.id,
            phase: 'TRANSFERRING',
            progress: total > 0 ? received / total : 0,
          );
        },
      );
      final bytes = await File(partPath).readAsBytes();
      final digest = sha256.convert(bytes).toString();
      if (digest != job['sha256']) {
        throw const FormatException('Transferred file failed verification.');
      }
      await File(partPath).rename(finalPath);
      final quality = AudioQuality.fromJson(
        job['quality'] as Map<String, dynamic>?,
      );
      final local = track.copyWith(localPath: finalPath, quality: quality);
      await database.saveTrack(
        TracksCompanion.insert(
          id: track.id,
          provider: 'monochrome',
          providerTrackId: track.providerTrackId,
          title: track.title,
          artist: track.artist,
          album: Value(track.album),
          artworkUrl: Value(track.artworkUrl),
          localPath: finalPath,
          sha256: digest,
          codec: Value(quality.codec),
          bitDepth: Value(quality.bitDepth),
          sampleRate: Value(quality.sampleRate),
          fileSize: bytes.length,
        ),
      );
      await dio.post<void>('/v1/downloads/$jobId/complete');
      state = TransferState(trackId: track.id, phase: 'COMPLETED', progress: 1);
      return local;
    } catch (error) {
      state = TransferState(
        trackId: track.id,
        phase: 'FAILED',
        error: _message(error),
      );
      return null;
    }
  }

  static String _safe(String value) =>
      value.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
  static String _message(Object error) {
    final message = error is DioException
        ? (error.response?.data is Map
                  ? (error.response!.data as Map)['detail']?.toString()
                  : null) ??
              "Couldn't reach the music source. Try again."
        : error.toString().replaceFirst('Bad state: ', '');
    if (message.contains('requires access') ||
        message.contains('only a preview')) {
      return 'This provider cannot supply a permitted full FLAC for this track. Try another result.';
    }
    return message;
  }
}

final downloadServiceProvider =
    StateNotifierProvider<DownloadService, TransferState>(DownloadService.new);
