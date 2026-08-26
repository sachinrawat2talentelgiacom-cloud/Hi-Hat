import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/browser_acquisition/browser_acquisition_screen.dart';
import '../models/track.dart';
import 'audio_engine.dart';
import 'download_service.dart';
import 'library_service.dart';

class TrackPlaybackCoordinator {
  TrackPlaybackCoordinator(this.ref);
  final Ref ref;
  bool _routeOpen = false;

  Future<TrackSummary?> play(
    TrackSummary track,
    NavigatorState navigator,
  ) async {
    ref.read(audioEngineProvider.notifier).showTrack(track);
    TrackSummary? local = track.isLocal ? track : null;
    if (local == null) {
      final row = await ref
          .read(databaseProvider)
          .findByProviderId(track.providerTrackId);
      if (row != null && await _localFileExists(row.localPath)) {
        local = localTrackSummary(row);
      }
    }
    if (local == null && track.provider == 'monochrome') {
      if (_routeOpen) return null;
      _routeOpen = true;
      ref.read(downloadServiceProvider.notifier).begin(track.id);
      try {
        local = await navigator.push<TrackSummary>(
          MaterialPageRoute(
            builder: (_) => BrowserAcquisitionScreen(track: track),
            fullscreenDialog: true,
          ),
        );
      } finally {
        _routeOpen = false;
      }
    } else if (local == null) {
      ref
          .read(downloadServiceProvider.notifier)
          .fail(track.id, 'This provider is not supported for acquisition.');
    }
    if (local != null) {
      await ref.read(audioEngineProvider.notifier).playLocal(local);
    }
    return local;
  }

  Future<bool> _localFileExists(String path) async {
    return File(path).exists();
  }
}

final trackPlaybackCoordinatorProvider = Provider(TrackPlaybackCoordinator.new);
