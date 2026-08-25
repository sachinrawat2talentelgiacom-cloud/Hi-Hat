// THESIS: acquisition is a visible handoff to a real provider browser, never a hidden token tunnel.
// OWN-WORLD: chamber surfaces frame one live chartreuse status line and the untouched provider page.
// STORY: verify normally when asked, let the visible Download action run, then return to local playback.
// FIRST VIEWPORT: compact status rail above the full browser; cancel and retry remain immediately reachable.
// FORM: adaptive operating surface extending Hi Hat's calibrated chamber, seed 30b4a877.
// FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/track.dart';
import '../../services/local_import_service.dart';

enum BrowserAcquisitionPhase {
  openingSource,
  waitingForAuthorization,
  matchingTrack,
  startingDownload,
  downloading,
  verifying,
  finalizing,
  ready,
  failed,
}

class BrowserAcquisitionScreen extends ConsumerStatefulWidget {
  const BrowserAcquisitionScreen({super.key, required this.track});
  final TrackSummary track;

  @override
  ConsumerState<BrowserAcquisitionScreen> createState() =>
      _BrowserAcquisitionScreenState();
}

class _BrowserAcquisitionScreenState
    extends ConsumerState<BrowserAcquisitionScreen> {
  BrowserAcquisitionPhase phase = BrowserAcquisitionPhase.openingSource;
  String? detail;
  DateTime started = DateTime.now();
  Timer? monitor;
  Timer? automationTimer;
  int stableReads = 0;
  int previousSize = -1;
  bool downloadRequested = false;
  bool automationRunning = false;
  bool scanRunning = false;
  String? expectedFilename;
  int? expectedLength;
  Set<String> existingDownloads = {};
  late Future<void> initialization;
  InAppWebViewController? webViewController;

  String get trackUrl =>
      'https://monochrome.tf/track/${Uri.encodeComponent(widget.track.providerTrackId)}';

  @override
  void initState() {
    super.initState();
    initialization = _snapshotDownloads();
  }

  @override
  void dispose() {
    monitor?.cancel();
    automationTimer?.cancel();
    super.dispose();
  }

  Future<void> _snapshotDownloads() async {
    final folder = await getDownloadsDirectory();
    if (folder == null || !await folder.exists()) return;
    existingDownloads = await folder
        .list()
        .where((entry) => entry is File)
        .map((entry) => entry.path)
        .toSet();
  }

  Future<void> _onLoaded(InAppWebViewController controller) async {
    if (downloadRequested || automationRunning) return;
    final current = await controller.getUrl();
    final expectedPath = '/track/${widget.track.providerTrackId}';
    if (current?.scheme != 'https' ||
        current?.host != 'monochrome.tf' ||
        current?.path != expectedPath) {
      if (mounted) {
        setState(() => phase = BrowserAcquisitionPhase.waitingForAuthorization);
      }
      return;
    }
    automationRunning = true;
    try {
      final result = await controller.evaluateJavascript(
        source: '''
          (() => {
            const verification = document.querySelector(
              'iframe[src*="turnstile"], input[name="cf-turnstile-response"], #challenge-form'
            );
            if (verification) return 'authorization';
            const button = document.querySelector('#download-track-btn');
            if (!button || button.offsetParent === null) return 'loading';
            button.click();
            return 'started';
          })();
        ''',
      );
      if (!mounted) return;
      final state = result?.toString().replaceAll('"', '');
      if (state == 'authorization') {
        setState(() => phase = BrowserAcquisitionPhase.waitingForAuthorization);
      } else if (state == 'started') {
        downloadRequested = true;
        setState(() => phase = BrowserAcquisitionPhase.startingDownload);
      } else {
        setState(() => phase = BrowserAcquisitionPhase.matchingTrack);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          phase = BrowserAcquisitionPhase.failed;
          detail = 'The provider page could not start its Download action.';
        });
      }
    } finally {
      automationRunning = false;
      if (mounted &&
          !downloadRequested &&
          phase != BrowserAcquisitionPhase.failed) {
        automationTimer?.cancel();
        automationTimer = Timer(
          const Duration(seconds: 2),
          () => _onLoaded(controller),
        );
      }
    }
  }

  void _onDownloadStarted(DownloadStartRequest request) {
    setState(() {
      phase = BrowserAcquisitionPhase.downloading;
      detail = request.suggestedFilename;
    });
    expectedFilename = request.suggestedFilename;
    expectedLength = request.contentLength > 0 ? request.contentLength : null;
    monitor?.cancel();
    monitor = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _scanForCompletedFile(),
    );
  }

  Future<void> _scanForCompletedFile() async {
    if (scanRunning) return;
    scanRunning = true;
    try {
      final folder = await getDownloadsDirectory();
      if (folder == null || !await folder.exists()) return;
      final candidates = await folder
          .list()
          .where((entry) => entry is File)
          .cast<File>()
          .where((file) {
            final lower = file.path.toLowerCase();
            final reportedName = expectedFilename;
            final nameMatches =
                reportedName == null ||
                file.uri.pathSegments.last.toLowerCase() ==
                    reportedName.toLowerCase();
            return lower.endsWith('.flac') &&
                nameMatches &&
                !existingDownloads.contains(file.path);
          })
          .toList();
      candidates.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      if (candidates.isEmpty) return;
      final file = candidates.first;
      if (file.lastModifiedSync().isBefore(started)) return;
      final size = await file.length();
      if (expectedLength != null && size != expectedLength) return;
      stableReads = size == previousSize ? stableReads + 1 : 0;
      previousSize = size;
      if (size <= 1024 || stableReads < 2) return;
      monitor?.cancel();
      await _finalize(file);
    } finally {
      scanRunning = false;
    }
  }

  Future<void> _finalize(File file) async {
    try {
      setState(() => phase = BrowserAcquisitionPhase.verifying);
      final local = await ref
          .read(localImportServiceProvider)
          .importForTrack(file, widget.track);
      if (!mounted) return;
      setState(() => phase = BrowserAcquisitionPhase.finalizing);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() => phase = BrowserAcquisitionPhase.ready);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.of(context).pop(local);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        phase = BrowserAcquisitionPhase.failed;
        detail = error.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.track.title, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          tooltip: 'Cancel acquisition',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    body: Column(
      children: [
        _AcquisitionStatus(
          phase: phase,
          detail: detail,
          onRetry: phase == BrowserAcquisitionPhase.failed
              ? () {
                  setState(() {
                    phase = BrowserAcquisitionPhase.openingSource;
                    detail = null;
                    downloadRequested = false;
                  });
                  webViewController?.reload();
                }
              : null,
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<void>(
            future: initialization,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              return InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(trackUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  useOnDownloadStart: true,
                  mediaPlaybackRequiresUserGesture: true,
                ),
                onWebViewCreated: (controller) =>
                    webViewController = controller,
                onLoadStop: (controller, _) => _onLoaded(controller),
                onReceivedError: (_, request, error) {
                  if (request.isForMainFrame == false || !mounted) return;
                  setState(() {
                    phase = BrowserAcquisitionPhase.failed;
                    detail = 'Monochrome could not be loaded. Check your connection and retry.';
                  });
                },
                onDownloadStartRequest: (_, request) =>
                    _onDownloadStarted(request),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _AcquisitionStatus extends StatelessWidget {
  const _AcquisitionStatus({required this.phase, this.detail, this.onRetry});
  final BrowserAcquisitionPhase phase;
  final String? detail;
  final VoidCallback? onRetry;

  String get label => switch (phase) {
    BrowserAcquisitionPhase.openingSource => 'Opening Monochrome…',
    BrowserAcquisitionPhase.waitingForAuthorization =>
      'Complete the provider verification to continue.',
    BrowserAcquisitionPhase.matchingTrack => 'Finding the requested track…',
    BrowserAcquisitionPhase.startingDownload => 'Starting the normal download…',
    BrowserAcquisitionPhase.downloading => 'Downloading FLAC…',
    BrowserAcquisitionPhase.verifying => 'Verifying the full FLAC…',
    BrowserAcquisitionPhase.finalizing => 'Adding to your local library…',
    BrowserAcquisitionPhase.ready => 'FLAC ready. Starting local playback...',
    BrowserAcquisitionPhase.failed => detail ?? 'Browser acquisition failed.',
  };

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          if (phase == BrowserAcquisitionPhase.failed)
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            )
          else
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    ),
  );
}
