import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../diagnostics/browser_acquisition_log.dart';
import '../features/browser_acquisition/browser_acquisition_screen.dart';
import '../models/track.dart';
import 'audio_engine.dart';
import 'download_service.dart';
import 'library_service.dart';
import 'library_folder_service.dart';

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
        final folderReady = await _ensureLibraryFolder(navigator);
        if (!folderReady) {
          ref
              .read(downloadServiceProvider.notifier)
              .fail(track.id, 'Choose a music folder before downloading.');
          return null;
        }
        final preferences = await SharedPreferences.getInstance();
        final debugVisible =
            preferences.getBool(providerBrowserDebugPreferenceKey) ?? false;
        local = await navigator.push<TrackSummary>(
          PageRouteBuilder<TrackSummary>(
            opaque: debugVisible,
            barrierColor: Colors.transparent,
            transitionDuration: debugVisible
                ? const Duration(milliseconds: 250)
                : Duration.zero,
            reverseTransitionDuration: debugVisible
                ? const Duration(milliseconds: 200)
                : Duration.zero,
            pageBuilder: (_, animation, secondaryAnimation) =>
                BrowserAcquisitionScreen(track: track),
            transitionsBuilder: (_, animation, secondaryAnimation, child) =>
                debugVisible
                ? FadeTransition(opacity: animation, child: child)
                : child,
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

  Future<bool> _ensureLibraryFolder(NavigatorState navigator) async {
    final folders = ref.read(libraryFolderServiceProvider);
    if (await folders.configuredPath() != null) return true;
    if (!navigator.mounted) return false;
    final choose = await showDialog<bool>(
      context: navigator.context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.folder_outlined),
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
      await folders.scanConfiguredFolder();
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
