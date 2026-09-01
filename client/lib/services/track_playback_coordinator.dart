import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/browser_acquisition/browser_acquisition_screen.dart';
import '../models/track.dart';
import 'audio_engine.dart';
import 'download_service.dart';
import 'library_service.dart';
import 'library_folder_service.dart';

class TrackPlaybackCoordinator {
  TrackPlaybackCoordinator(this.ref);
  final Ref ref;
  final Map<String, Completer<TrackSummary?>> _activeSessions = {};
  final Map<String, OverlayEntry> _activeEntries = {};

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
      if (_activeSessions.containsKey(track.id)) {
        ref.read(downloadServiceProvider.notifier).focus(track.id);
        return _activeSessions[track.id]!.future;
      }

      ref.read(downloadServiceProvider.notifier).begin(track.id, track: track);
      final completer = Completer<TrackSummary?>();
      _activeSessions[track.id] = completer;

      try {
        final folderReady = await _ensureLibraryFolder(navigator);
        if (!folderReady) {
          ref
              .read(downloadServiceProvider.notifier)
              .fail(
                track.id,
                'Choose a music folder before downloading.',
                track: track,
              );
          _activeSessions.remove(track.id);
          return null;
        }
        local = await _runAcquisitionInOverlay(track, navigator, completer);
      } catch (error) {
        ref
            .read(downloadServiceProvider.notifier)
            .fail(track.id, 'Track preparation stopped: $error', track: track);
      } finally {
        _activeSessions.remove(track.id);
      }
    } else if (local == null) {
      ref
          .read(downloadServiceProvider.notifier)
          .fail(
            track.id,
            'This provider is not supported for acquisition.',
            track: track,
          );
    }
    if (local != null) {
      await ref.read(audioEngineProvider.notifier).playLocal(local);
    }
    return local;
  }

  Future<bool> _localFileExists(String path) async {
    return File(path).exists();
  }

  Future<TrackSummary?> _runAcquisitionInOverlay(
    TrackSummary track,
    NavigatorState navigator,
    Completer<TrackSummary?> completer,
  ) async {
    final overlay = navigator.overlay;
    if (overlay == null) {
      throw StateError('The app overlay is unavailable.');
    }
    late final OverlayEntry entry;
    var removed = false;
    void finish(TrackSummary? result) {
      if (removed) return;
      removed = true;
      _activeEntries.remove(track.id);
      entry.remove();
      entry.dispose();
      if (!completer.isCompleted) completer.complete(result);
    }

    entry = OverlayEntry(
      maintainState: true,
      builder: (_) =>
          BrowserAcquisitionScreen(track: track, onFinished: finish),
    );
    _activeEntries[track.id] = entry;
    overlay.insert(entry);
    return completer.future;
  }

  Future<bool> _ensureLibraryFolder(NavigatorState navigator) async {
    final folders = ref.read(libraryFolderServiceProvider);
    if (await folders.configuredPath() != null) return true;
    if (!navigator.mounted) return false;
    final choose = await showDialog<bool>(
      context: navigator.context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.folder_rounded),
        title: const Text('Choose your music folder'),
        content: const Text(
          'Hi Hat will save this and future downloads there, organized by artist and album.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Choose folder'),
          ),
        ],
      ),
    );
    if (choose != true) return false;
    try {
      final selected = await folders.chooseFolder();
      if (selected == null) return false;
      return true;
    } on FileSystemException {
      if (navigator.mounted) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hi Hat cannot write to that folder. Choose another one.',
            ),
          ),
        );
      }
      return false;
    }
  }
}

final trackPlaybackCoordinatorProvider = Provider(TrackPlaybackCoordinator.new);
