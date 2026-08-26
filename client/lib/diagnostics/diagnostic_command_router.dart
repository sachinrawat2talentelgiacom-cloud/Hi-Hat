import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../features/search/search_controller.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/download_service.dart';
import '../services/library_service.dart';
import '../services/track_playback_coordinator.dart';
import 'diagnostic_state_store.dart';

class DiagnosticCommandRouter {
  DiagnosticCommandRouter(this.ref);
  final WidgetRef ref;

  Future<Map<String, Object?>> handle(Map<String, dynamic> request) async {
    final command = (request['command'] ?? '').toString().toUpperCase();
    final payload = request['payload'] is Map
        ? Map<String, dynamic>.from(request['payload'] as Map)
        : <String, dynamic>{};
    ref.read(diagnosticStateProvider.notifier).command(command);
    switch (command) {
      case 'PING':
        return {'ok': true, 'app': 'Hi Hat', 'diagnosticsReady': true};
      case 'GET_APP_STATE':
        return {'ok': true, 'state': 'READY'};
      case 'SEARCH':
        await ref
            .read(searchControllerProvider.notifier)
            .search((payload['query'] ?? '').toString());
        return {'ok': true, ..._searchSnapshot()};
      case 'GET_SEARCH_STATE':
      case 'GET_SEARCH_RESULTS':
        return {'ok': true, ..._searchSnapshot()};
      case 'RESET_SEARCH':
        ref.read(searchControllerProvider.notifier).cancel();
        return {'ok': true, 'state': 'IDLE'};
      case 'PLAY_TRACK':
        final id = (payload['trackId'] ?? '').toString();
        final results =
            ref.read(searchControllerProvider).valueOrNull ?? const [];
        final track = results.where((item) => item.id == id).firstOrNull;
        final navigator = navigatorKey.currentState;
        if (track == null || navigator == null) {
          return {'ok': false, 'error': 'TRACK_OR_NAVIGATOR_NOT_READY'};
        }
        unawaited(_play(track, navigator));
        return {'ok': true, 'state': 'LOCAL_LOOKUP', 'trackId': track.id};
      case 'GET_ACQUISITION_STATE':
      case 'GET_DOWNLOAD_STATE':
        final transfer = ref.read(downloadServiceProvider);
        return {
          'ok': true,
          'state': transfer.phase ?? 'IDLE',
          'trackId': transfer.trackId,
          'progress': transfer.progress,
          'error': transfer.error,
        };
      case 'GET_LOCAL_TRACK':
      case 'GET_METADATA':
        final providerId =
            (payload['providerTrackId'] ?? payload['trackId'] ?? '')
                .toString()
                .replaceFirst('monochrome:', '');
        final row = await ref
            .read(databaseProvider)
            .findByProviderId(providerId);
        return {
          'ok': true,
          'ready': row != null && await File(row.localPath).exists(),
          if (row != null) ...{
            'title': row.title,
            'artist': row.artist,
            'album': row.album,
            'filePath': row.localPath,
            'codec': row.codec,
            'sampleRate': row.sampleRate,
            'bitDepth': row.bitDepth,
            'channels': row.channels,
            'durationSeconds': row.durationSeconds,
            'fileSize': row.fileSize,
            'sha256': row.sha256,
          },
        };
      case 'GET_PLAYBACK_STATE':
        final playback = ref.read(audioEngineProvider);
        return {
          'ok': true,
          'state': playback.playing ? 'PLAYING' : 'PAUSED',
          'positionSeconds': playback.position.inMilliseconds / 1000,
          'durationSeconds': playback.duration.inMilliseconds / 1000,
          'isPlaying': playback.playing,
          'localPath': playback.track?.localPath,
        };
      case 'STOP_PLAYBACK':
        await ref.read(audioEngineProvider.notifier).stop();
        return {'ok': true, 'state': 'STOPPED'};
      case 'RESET_DIAGNOSTICS':
        ref.read(diagnosticStateProvider.notifier).reset();
        return {'ok': true};
      default:
        return {'ok': false, 'error': 'UNKNOWN_COMMAND', 'command': command};
    }
  }

  Map<String, Object?> _searchSnapshot() {
    final search = ref.read(searchControllerProvider);
    return search.when(
      loading: () => {'state': 'SEARCHING', 'results': const []},
      error: (error, _) => {
        'state': 'ERROR',
        'error': error.toString(),
        'results': const [],
      },
      data: (results) => {
        'state': results.isEmpty ? 'EMPTY' : 'RESULTS_READY',
        'results': results.map(_track).toList(growable: false),
      },
    );
  }

  Future<void> _play(TrackSummary track, NavigatorState navigator) async {
    try {
      await ref.read(trackPlaybackCoordinatorProvider).play(track, navigator);
    } catch (error, stackTrace) {
      ref.read(diagnosticStateProvider.notifier).error(error.toString());
      debugPrint('Diagnostic Play failed: $error\n$stackTrace');
    }
  }

  static Map<String, Object?> _track(TrackSummary track) => {
    'id': track.id,
    'providerId': track.providerTrackId,
    'provider': track.provider,
    'title': track.title,
    'artist': track.artist,
    'album': track.album,
    'durationSeconds': track.durationSeconds,
    'quality': track.quality.display,
    'localPath': track.localPath,
  };
}
