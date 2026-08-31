// THESIS: acquisition is a visible handoff to a real provider browser, never a hidden token tunnel.
// OWN-WORLD: chamber surfaces frame one live chartreuse status line and the untouched provider page.
// STORY: verify normally when asked, let the visible Download action run, then return to local playback.
// FIRST VIEWPORT: compact status rail above the full browser; cancel and retry remain immediately reachable.
// FORM: adaptive operating surface extending Hi Hat's calibrated chamber, seed 30b4a877.
// FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../diagnostics/browser_acquisition_log.dart';
import '../../models/track.dart';
import '../../services/acquisition_supervisor.dart';
import '../../services/download_service.dart';
import '../../services/local_import_service.dart';
import '../../widgets/track_artwork.dart';

String acquisitionSearchQuery(TrackSummary track) {
  final primaryArtist = track.artist
      .split(RegExp(r',|&|\bfeat(?:uring)?\.?\b', caseSensitive: false))
      .first
      .trim();
  return [
    track.title.trim(),
    primaryArtist,
  ].where((part) => part.isNotEmpty).join(' ');
}

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
  const BrowserAcquisitionScreen({
    super.key,
    required this.track,
    required this.onFinished,
  });
  final TrackSummary track;
  final ValueChanged<TrackSummary?> onFinished;

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
  Timer? downloadStartDeadline;
  int stableReads = 0;
  int previousSize = -1;
  bool downloadRequested = false;
  bool automationRunning = false;
  final acquisitionSupervisor = AcquisitionSupervisor();
  bool scanRunning = false;
  bool showProviderBrowser = false;
  bool debugVisible = false;
  bool debugPreferenceLoaded = false;
  bool disposing = false;
  bool finished = false;
  bool cancelled = false;
  double lastReportedProgress = 0;
  double? providerDurationSeconds;
  String? expectedFilename;
  int? expectedLength;
  File? controlledDownloadFile;
  TrackSummary? completedTrack;
  Set<String> existingDownloads = {};
  late Future<void> initialization;
  InAppWebViewController? webViewController;
  CancelToken? httpCancelToken;
  RandomAccessFile? blobOutput;
  BrowserAcquisitionLog? acquisitionLog;

  String get searchQuery => acquisitionSearchQuery(widget.track);

  String get primaryArtist => widget.track.artist
      .split(RegExp(r',|&|\bfeat(?:uring)?\.?\b', caseSensitive: false))
      .first
      .trim();

  String get trackUrl =>
      'https://monochrome.tf/search/${Uri.encodeComponent(searchQuery)}';

  String? _safeUrl(Object? value) {
    if (value == null) return null;
    final parsed = Uri.tryParse(value.toString());
    return parsed?.replace(query: '', fragment: '').toString() ??
        '<invalid-url>';
  }

  @override
  void initState() {
    super.initState();
    initialization = _snapshotDownloads();
    SharedPreferences.getInstance().then((preferences) async {
      if (!mounted) return;
      setState(() {
        debugVisible =
            preferences.getBool(providerBrowserDebugPreferenceKey) ?? false;
        showProviderBrowser = debugVisible;
        debugPreferenceLoaded = true;
      });
      if (debugVisible) {
        acquisitionLog = BrowserAcquisitionLog(
          trackId: widget.track.providerTrackId,
          onEntry: (_) {
            if (mounted && !disposing) setState(() {});
          },
        );
        await acquisitionLog!.start();
        await acquisitionLog!.event('DEBUG_MODE_ENABLED', {
          'provider': widget.track.provider,
          'title': widget.track.title,
          'artist': widget.track.artist,
          'album': widget.track.album,
          'searchQuery': searchQuery,
          'targetUrl': trackUrl,
          'platform': Platform.operatingSystem,
        });
      }
    });
  }

  @override
  void dispose() {
    disposing = true;
    monitor?.cancel();
    automationTimer?.cancel();
    downloadStartDeadline?.cancel();
    httpCancelToken?.cancel('Acquisition disposed.');
    final output = blobOutput;
    blobOutput = null;
    if (output != null) unawaited(output.close());
    acquisitionLog?.close();
    super.dispose();
  }

  Future<void> _snapshotDownloads() async {
    try {
      final folder = await getDownloadsDirectory();
      if (folder == null || !await folder.exists()) return;
      existingDownloads = await folder
          .list()
          .where((entry) => entry is File)
          .map((entry) => entry.path)
          .toSet();
    } catch (_) {
      // Scoped storage or unsupported platform error; safe to ignore.
    }
  }

  Future<void> _onLoaded(InAppWebViewController controller) async {
    if (cancelled || downloadRequested || automationRunning) return;
    if (!acquisitionSupervisor.beginSearchAttempt()) return;
    // Lock before the first await: WebView can emit load and progress events
    // together, and both must not enter the download action concurrently.
    automationRunning = true;
    await acquisitionLog?.event('AUTOMATION_TICK', {
      'downloadRequested': downloadRequested,
      'automationRunning': automationRunning,
      'attempt': acquisitionSupervisor.searchAttempts,
    });
    final current = await controller.getUrl();
    await acquisitionLog?.event('PAGE_URL_READ', {
      'url': _safeUrl(current),
      'expectedUrl': trackUrl,
    });
    final expectedPath = Uri.parse(trackUrl).path;
    final currentDecoded = Uri.decodeComponent(current?.path ?? '')
        .replaceAll(RegExp(r'/+$'), '')
        .toLowerCase();
    final expectedDecoded = Uri.decodeComponent(expectedPath)
        .replaceAll(RegExp(r'/+$'), '')
        .toLowerCase();
    if (current?.scheme != 'https' ||
        current?.host != 'monochrome.tf' ||
        currentDecoded != expectedDecoded) {
      if (mounted) {
        setState(() {
          phase = BrowserAcquisitionPhase.waitingForAuthorization;
          showProviderBrowser = true;
        });
        ref
            .read(downloadServiceProvider.notifier)
            .update(widget.track.id, 'AUTH_REQUIRED', progress: 0.04);
        ref.read(downloadServiceProvider.notifier).focus(widget.track.id);
      }
      await acquisitionLog?.event('AUTH_OR_NAVIGATION_REQUIRED', {
        'url': _safeUrl(current),
        'expectedPath': expectedPath,
      });
      automationRunning = false;
      return;
    }
    try {
      final result = await controller.evaluateJavascript(
        source:
            '''
          (async () => {
            const verification = document.querySelector(
              'iframe[src*="turnstile"], input[name="cf-turnstile-response"], #challenge-form, [data-sitekey]'
            );
            if (verification && verification.offsetParent !== null) {
              return 'authorization';
            }

            const trackId = ${jsonEncode(widget.track.providerTrackId)};
            const wantedTitle = ${jsonEncode(widget.track.title.toLowerCase())};
            const wantedArtist = ${jsonEncode(primaryArtist.toLowerCase())};
            const candidateOffset = ${acquisitionSupervisor.candidateOffset};
            const normalize = (value) => (value || '')
              .toLowerCase()
              .replace(/\\s+/g, ' ')
              .trim();
            const visible = (element) => {
              if (!element) return false;
              const style = window.getComputedStyle(element);
              return style.display !== 'none' && style.visibility !== 'hidden' && element.offsetParent !== null;
            };
            const rowFor = (element) => element?.closest(
              'li, [role="row"], [data-type="track"], .track, .track-item, .media-item, tr'
            ) || element;
            const matchesWantedRow = (element) => {
              const row = rowFor(element);
              if (!visible(row)) return false;
              const labels = [...row.querySelectorAll('span, p, a, strong, small, div')]
                .filter(visible)
                .map((label) => normalize(label.innerText || label.textContent));
              const titleMatch = labels.some((text) =>
                text === wantedTitle || text.startsWith(`\${wantedTitle} (`) ||
                text.startsWith(`\${wantedTitle} -`)
              );
              const artistMatch = !wantedArtist || labels.some((text) =>
                text === wantedArtist || text.startsWith(`\${wantedArtist},`) ||
                text.startsWith(`\${wantedArtist} &`) ||
                text.startsWith(`\${wantedArtist} feat`)
              );
              return titleMatch && artistMatch;
            };
            const notices = () => [...document.querySelectorAll(
              '[role="alert"], [role="status"], .toast, [class*="toast" i], [class*="notification" i]'
            )].filter(visible).map((element) =>
              normalize(element.innerText || element.textContent)
            ).filter(Boolean);
            const clickAndReport = async (button, action, row) => {
              const before = new Set(notices());
              button.click();
              await new Promise((resolve) => setTimeout(resolve, 250));
              const message = notices().find((text) => !before.has(text));
              if (message) return `provider-error:\${message}`;
              return `started:\${action}:\${normalize(row.innerText).slice(0, 160)}`;
            };

            let target = document.querySelector(
              `[data-track-id="\${CSS.escape(trackId)}"], ` +
              `[data-id="\${CSS.escape(trackId)}"], ` +
              `a[href*="/track/\${CSS.escape(trackId)}"]`
            );
            if (!visible(target) || !matchesWantedRow(target)) {
              target = null;
            } else {
              target = rowFor(target);
            }

            if (!target) {
              const artistLabels = [...document.querySelectorAll(
                'span, p, a, strong, small, div'
              )].filter((element) => {
                if (!visible(element)) return false;
                const text = normalize(element.innerText || element.textContent);
                if (text === wantedArtist) return true;
                if (!text.startsWith(wantedArtist)) return false;
                return text.length <= wantedArtist.length + 40;
              });

              const candidates = [];
              for (const label of artistLabels) {
                let element = label;
                for (let depth = 0; element && depth < 7; depth += 1) {
                  const text = normalize(element.innerText || element.textContent);
                  const rect = element.getBoundingClientRect();
                  const compactRow = rect.height >= 20 && rect.height <= 200 &&
                    rect.width >= 50 && text.length <= 300;
                  if (compactRow && text.includes(wantedTitle) &&
                      (!wantedArtist || text.includes(wantedArtist)) &&
                      !text.startsWith('search results for') &&
                      matchesWantedRow(element)) {
                    candidates.push({
                      element,
                      text,
                      area: rect.width * rect.height,
                      top: Math.round(rect.top),
                    });
                  }
                  element = element.parentElement;
                }
              }
              candidates.sort((a, b) => a.area - b.area || a.text.length - b.text.length);
              const uniqueCandidates = candidates.filter((candidate, index, all) =>
                all.findIndex((other) => other.top === candidate.top) === index
              );
              target = uniqueCandidates[candidateOffset]?.element || null;
            }

            if (!target) {
              const allRows = [...document.querySelectorAll('li, [role="row"], [data-type="track"], .track, .track-item, .media-item, tr')];
              const matchingRows = [];
              for (const row of allRows) {
                if (!visible(row)) continue;
                if (matchesWantedRow(row)) {
                  matchingRows.push(row);
                }
              }
              target = matchingRows[candidateOffset] || null;
            }

            if (!target) return 'loading:matching-row-not-found';
            const row = rowFor(target);
            row.scrollIntoView({block: 'center', behavior: 'instant'});

            const inlineDownload = row.querySelector(
              '[data-action="download"], button[title*="download" i], button[aria-label*="download" i], a[download]'
            );
            if (inlineDownload && visible(inlineDownload)) {
              return await clickAndReport(inlineDownload, 'inline-download', row);
            }

            const rect = row.getBoundingClientRect();
            const clickX = rect.left + Math.min(rect.width / 2, 120);
            const clickY = rect.top + Math.min(rect.height / 2, 24);

            row.dispatchEvent(new MouseEvent('contextmenu', {
              bubbles: true,
              cancelable: true,
              view: window,
              button: 2,
              buttons: 2,
              clientX: clickX,
              clientY: clickY,
            }));

            const findContextDownload = () => {
              const attributed = document.querySelector(
                '#context-menu li[data-action="download"], #context-menu [data-action="download"], li[data-action="download"], [data-action="download"]'
              );
              if (visible(attributed)) return attributed;
              const menuItems = [...document.querySelectorAll(
                '[role="menuitem"], [role="menu"] li, [class*="menu" i] li, [class*="menu" i] button, [class*="menu" i] div'
              )].filter(visible);
              return menuItems.find((item) =>
                normalize(item.innerText || item.textContent) === 'download'
              ) || null;
            };
            let contextDownload = findContextDownload();
            if (!contextDownload) {
              const moreButton = row.querySelector(
                'button[aria-label*="more" i], button[title*="more" i], .more-button, [data-action="more"], .track-more, .actions-button'
              );
              if (moreButton) {
                moreButton.click();
              }
            }

            // Provider menus render asynchronously. Wait briefly here instead
            // of rescanning the entire result page on the next polling tick.
            for (let attempt = 0; !contextDownload && attempt < 4; attempt += 1) {
              await new Promise((resolve) => setTimeout(resolve, 50));
              contextDownload = findContextDownload();
            }

            if (!contextDownload) return 'loading:context-download-not-found';
            return await clickAndReport(contextDownload, 'context-download', row);
          })();
        ''',
      );
      if (!mounted) return;
      final state = result?.toString().replaceAll('"', '');
      await acquisitionLog?.event('AUTOMATION_RESULT', {
        'rawResult': result?.toString(),
        'interpretedState': state,
      });
      if (state == 'authorization') {
        setState(() {
          phase = BrowserAcquisitionPhase.waitingForAuthorization;
          showProviderBrowser = true;
        });
        ref
            .read(downloadServiceProvider.notifier)
            .update(widget.track.id, 'AUTH_REQUIRED', progress: 0.04);
        ref.read(downloadServiceProvider.notifier).focus(widget.track.id);
      } else if (state?.startsWith('started:') ?? false) {
        await acquisitionLog?.event('DOWNLOAD_BUTTON_CLICKED', {
          'action': state,
        });
        acquisitionSupervisor.markActionIssued();
        setState(() {
          phase = BrowserAcquisitionPhase.startingDownload;
          showProviderBrowser = debugVisible;
        });
        ref
            .read(downloadServiceProvider.notifier)
            .update(widget.track.id, 'STARTING_DOWNLOAD', progress: 0.1);
        ref
            .read(downloadServiceProvider.notifier)
            .setMinimized(widget.track.id, true);
      } else if (state?.startsWith('provider-error:') ?? false) {
        final message = state!.substring('provider-error:'.length).trim();
        _failAutomation(
          message.isEmpty ? 'The provider rejected the download.' : message,
        );
      } else {
        setState(() => phase = BrowserAcquisitionPhase.matchingTrack);
        ref
            .read(downloadServiceProvider.notifier)
            .update(widget.track.id, 'MATCHING_TRACK', progress: 0.06);
      }
    } catch (error, stackTrace) {
      await acquisitionLog?.event('AUTOMATION_ERROR', {
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      });
      if (mounted) {
        setState(() {
          phase = BrowserAcquisitionPhase.failed;
          detail = 'The provider page could not start its Download action.';
        });
        ref
            .read(downloadServiceProvider.notifier)
            .fail(
              widget.track.id,
              'The provider page could not start its Download action.',
            );
      }
    } finally {
      automationRunning = false;
      if (mounted &&
          !downloadRequested &&
          phase != BrowserAcquisitionPhase.failed &&
          phase != BrowserAcquisitionPhase.waitingForAuthorization) {
        automationTimer?.cancel();
        automationTimer = Timer(
          AcquisitionSupervisor.pollInterval,
          () => _superviseAcquisition(controller),
        );
      }
    }
  }

  void _superviseAcquisition(InAppWebViewController controller) {
    if (!mounted || cancelled || downloadRequested) return;
    final directive = acquisitionSupervisor.check();
    acquisitionLog?.event('ACQUISITION_SUPERVISOR_CHECK', {
      'directive': directive.name,
      'searchAttempts': acquisitionSupervisor.searchAttempts,
      'downloadStartChecks': acquisitionSupervisor.downloadStartChecks,
    });
    switch (directive) {
      case AcquisitionDirective.search:
        _onLoaded(controller);
        return;
      case AcquisitionDirective.waitForDownload:
        automationTimer?.cancel();
        automationTimer = Timer(
          AcquisitionSupervisor.pollInterval,
          () => _superviseAcquisition(controller),
        );
        return;
      case AcquisitionDirective.searchFailed:
        final lastFailure = acquisitionSupervisor.lastFailure;
        _failAutomation(
          'The requested track was not found after '
          '${acquisitionSupervisor.maximumChecks} checks.'
          '${lastFailure == null ? '' : ' Last failure: $lastFailure'}',
        );
        return;
      case AcquisitionDirective.downloadFailed:
        _failAutomation(
          'The provider accepted Download, but no file transfer started.',
        );
        return;
      case AcquisitionDirective.complete:
        return;
    }
  }

  void _failAutomation(String message) {
    unawaited(_handleAcquisitionFailure(message));
  }

  Future<DownloadStartResponse?> _onDownloadStarted(
    DownloadStartRequest request,
  ) async {
    if (cancelled) return null;
    downloadRequested = true;
    acquisitionSupervisor.markTransferStarted();
    automationTimer?.cancel();
    downloadStartDeadline?.cancel();
    await acquisitionLog?.event('DOWNLOAD_CALLBACK_RECEIVED', {
      'url': _safeUrl(request.url),
      'suggestedFilename': request.suggestedFilename,
      'contentLength': request.contentLength,
      'mimeType': request.mimeType,
    });
    setState(() {
      phase = BrowserAcquisitionPhase.downloading;
      detail = request.suggestedFilename;
    });
    ref
        .read(downloadServiceProvider.notifier)
        .update(widget.track.id, 'DOWNLOADING', progress: 0.1);
    expectedFilename = request.suggestedFilename;
    expectedLength = request.contentLength > 0 ? request.contentLength : null;

    final root = await getApplicationSupportDirectory();
    if (cancelled) return null;
    final folder = Directory(
      p.join(root.path, 'Acquisitions', widget.track.providerTrackId),
    );
    await folder.create(recursive: true);
    final incoming = File(p.join(folder.path, 'incoming.flac'));
    if (await incoming.exists()) await incoming.delete();
    controlledDownloadFile = incoming;
    await acquisitionLog?.event('DOWNLOAD_DESTINATION_ASSIGNED', {
      'path': incoming.path,
    });

    monitor?.cancel();
    monitor = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _scanForCompletedFile(),
    );

    if (Platform.isWindows) {
      return DownloadStartResponse(
        handled: true,
        resultFilePath: incoming.path,
      );
    }

    final uri = request.url;
    if (uri.scheme == 'blob') {
      _extractAndSaveBlob(uri.toString(), incoming);
    } else if (uri.scheme == 'data') {
      _saveDataUri(uri.toString(), incoming);
    } else if (uri.scheme == 'http' || uri.scheme == 'https') {
      _downloadHttpUri(uri, incoming, userAgent: request.userAgent);
    }
    return null;
  }

  Future<void> _extractAndSaveBlob(String blobUrl, File destination) async {
    if (cancelled) return;
    try {
      await acquisitionLog?.event('EXTRACTING_BLOB', {'blobUrl': blobUrl});
      final js =
          '''
        (async () => {
          try {
            const response = await fetch(${jsonEncode(blobUrl)});
            const blob = await response.blob();
            return new Promise((resolve, reject) => {
              const reader = new FileReader();
              reader.onloadend = () => resolve(reader.result);
              reader.onerror = (e) => reject(e.toString());
              reader.readAsDataURL(blob);
            });
          } catch (err) {
            return 'error:' + err.toString();
          }
        })();
      ''';
      final result = await webViewController?.evaluateJavascript(source: js);
      if (cancelled) return;
      final dataString = result?.toString().replaceAll('"', '');
      if (dataString != null && dataString.startsWith('data:')) {
        await _saveDataUri(dataString, destination);
      } else {
        await acquisitionLog?.event('BLOB_EXTRACTION_FAILED', {
          'result': result?.toString(),
        });
      }
    } catch (e, stack) {
      await acquisitionLog?.event('BLOB_EXTRACTION_ERROR', {
        'error': e.toString(),
        'stack': stack.toString(),
      });
    }
  }

  Future<void> _saveDataUri(String dataUri, File destination) async {
    if (cancelled) return;
    try {
      final commaIndex = dataUri.indexOf(',');
      if (commaIndex == -1) return;
      final base64String = dataUri.substring(commaIndex + 1);
      final bytes = base64Decode(base64String);
      if (cancelled) return;
      await destination.parent.create(recursive: true);
      if (cancelled) return;
      await destination.writeAsBytes(bytes, flush: true);
      if (cancelled) return;
      await acquisitionLog?.event('DOWNLOAD_SAVED_FROM_DATA', {
        'path': destination.path,
        'bytes': bytes.length,
      });
      monitor?.cancel();
      await _finalize(destination);
    } catch (e, stack) {
      await acquisitionLog?.event('SAVE_DATA_URI_ERROR', {
        'error': e.toString(),
        'stack': stack.toString(),
      });
    }
  }

  Future<void> _downloadHttpUri(
    WebUri uri,
    File destination, {
    String? userAgent,
  }) async {
    if (cancelled) return;
    try {
      await acquisitionLog?.event('DOWNLOADING_HTTP_URI', {
        'url': _safeUrl(uri),
      });
      final dio = Dio();
      final cancelToken = CancelToken();
      httpCancelToken = cancelToken;
      final options = Options(
        headers: {
          if (userAgent != null && userAgent.isNotEmpty)
            'User-Agent': userAgent,
        },
      );
      await destination.parent.create(recursive: true);
      final response = await dio.downloadUri(
        Uri.parse(uri.toString()),
        destination.path,
        options: options,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (cancelled || total <= 0) return;
          final ratio = (received / total).clamp(0.0, 1.0);
          ref
              .read(downloadServiceProvider.notifier)
              .update(
                widget.track.id,
                'DOWNLOADING',
                progress: 0.1 + (ratio * 0.8),
              );
        },
      );
      if (!cancelled) {
        await acquisitionLog?.event('DOWNLOAD_SAVED_FROM_HTTP', {
          'path': destination.path,
          'bytes': await destination.length(),
          'statusCode': response.statusCode,
        });
        monitor?.cancel();
        await _finalize(destination);
      }
    } on DioException catch (e, stack) {
      if (CancelToken.isCancel(e) || cancelled) return;
      await acquisitionLog?.event('HTTP_DOWNLOAD_ERROR', {
        'error': e.toString(),
        'stack': stack.toString(),
      });
      await _failDownload(
        'The file transfer failed. Check your connection and retry.',
      );
    } catch (e, stack) {
      if (cancelled) return;
      await acquisitionLog?.event('HTTP_DOWNLOAD_ERROR', {
        'error': e.toString(),
        'stack': stack.toString(),
      });
      await _failDownload(
        'The downloaded file could not be saved. Please retry.',
      );
    }
  }

  Future<void> _failDownload(String message) =>
      _handleAcquisitionFailure(message, partial: controlledDownloadFile);

  Future<void> _handleAcquisitionFailure(
    String message, {
    File? partial,
  }) async {
    if (!mounted || cancelled || finished) return;
    monitor?.cancel();
    automationTimer?.cancel();
    final recovery = acquisitionSupervisor.classifyFailure(message);
    await acquisitionLog?.event('ACQUISITION_FAILURE_CLASSIFIED', {
      'message': message,
      'recovery': recovery.name,
      'recoveryAttempt': acquisitionSupervisor.recoveryAttempts,
      'candidateOffset': acquisitionSupervisor.candidateOffset,
    });
    if (recovery == AcquisitionRecovery.stop) {
      _showTerminalFailure(message);
      return;
    }

    final failedFile = partial ?? controlledDownloadFile;
    if (failedFile != null) {
      try {
        if (await failedFile.exists()) await failedFile.delete();
      } catch (_) {
        // The next controlled download deletes any file still held by WebView.
      }
    }
    downloadRequested = false;
    automationRunning = false;
    controlledDownloadFile = null;
    expectedFilename = null;
    expectedLength = null;
    stableReads = 0;
    previousSize = -1;
    setState(() {
      phase = BrowserAcquisitionPhase.matchingTrack;
      detail = recovery == AcquisitionRecovery.retryNextCandidate
          ? 'That result did not match. Trying the next best result…'
          : 'The attempt failed. Retrying automatically…';
    });
    ref
        .read(downloadServiceProvider.notifier)
        .update(widget.track.id, 'MATCHING_TRACK', progress: 0.06);
    final controller = webViewController;
    if (controller == null) {
      _showTerminalFailure('$message The provider browser is unavailable.');
      return;
    }
    try {
      await controller.reload();
    } catch (_) {
      _showTerminalFailure('$message The provider page could not be reloaded.');
      return;
    }
    automationTimer?.cancel();
    automationTimer = Timer(
      AcquisitionSupervisor.pollInterval,
      () => _onLoaded(controller),
    );
  }

  void _showTerminalFailure(String message) {
    if (!mounted || cancelled || finished) return;
    setState(() {
      phase = BrowserAcquisitionPhase.failed;
      detail = message;
      showProviderBrowser = true;
    });
    ref.read(downloadServiceProvider.notifier).fail(widget.track.id, message);
  }

  Future<bool> _startChunkedBlobDownload(String? filename) async {
    if (cancelled) return false;
    downloadRequested = true;
    acquisitionSupervisor.markTransferStarted();
    automationTimer?.cancel();
    downloadStartDeadline?.cancel();
    setState(() {
      phase = BrowserAcquisitionPhase.downloading;
      detail = filename ?? expectedFilename;
    });
    ref
        .read(downloadServiceProvider.notifier)
        .update(widget.track.id, 'DOWNLOADING', progress: 0.1);
    final root = await getApplicationSupportDirectory();
    if (cancelled) return false;
    final folder = Directory(
      p.join(root.path, 'Acquisitions', widget.track.providerTrackId),
    );
    await folder.create(recursive: true);
    final incoming = File(p.join(folder.path, 'incoming.flac'));
    if (await incoming.exists()) await incoming.delete();
    controlledDownloadFile = incoming;
    final previous = blobOutput;
    if (previous != null) await previous.close();
    blobOutput = await incoming.open(mode: FileMode.write);
    return true;
  }

  Future<bool> _appendChunkedBlob(String encodedChunk) async {
    if (cancelled) return false;
    final output = blobOutput;
    if (output == null) return false;
    await output.writeFrom(base64Decode(encodedChunk));
    return true;
  }

  Future<bool> _finishChunkedBlobDownload() async {
    final output = blobOutput;
    blobOutput = null;
    if (output == null) return false;
    await output.flush();
    await output.close();
    if (cancelled) return false;
    final incoming = controlledDownloadFile;
    if (incoming == null) return false;
    await _finalize(incoming);
    return true;
  }

  Future<void> _scanForCompletedFile() async {
    if (cancelled || scanRunning) return;
    scanRunning = true;
    try {
      if (DateTime.now().difference(started) > const Duration(minutes: 3)) {
        monitor?.cancel();
        const message = 'The provider download exceeded the 3-minute deadline.';
        if (mounted) {
          setState(() {
            phase = BrowserAcquisitionPhase.failed;
            detail = message;
          });
          ref
              .read(downloadServiceProvider.notifier)
              .fail(widget.track.id, 'DOWNLOAD_TIMEOUT: $message');
        }
        return;
      }
      final controlled = controlledDownloadFile;
      final candidates = <File>[];
      if (controlled != null && await controlled.exists()) {
        candidates.add(controlled);
      } else {
        try {
          final folder = await getDownloadsDirectory();
          if (folder != null && await folder.exists()) {
            candidates.addAll(
              await folder
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
                  .toList(),
            );
          }
        } catch (_) {
          // Ignore directory access restriction on mobile platforms
        }
      }
      candidates.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      if (candidates.isEmpty) {
        await acquisitionLog?.event('FILE_SCAN_NO_CANDIDATE', {
          'controlledPath': controlled?.path,
          'expectedFilename': expectedFilename,
        });
        return;
      }
      final file = candidates.first;
      if (file.lastModifiedSync().isBefore(started)) return;
      final size = await file.length();
      await acquisitionLog?.event('FILE_CANDIDATE_OBSERVED', {
        'path': file.path,
        'size': size,
        'expectedLength': expectedLength,
        'stableReads': stableReads,
      });
      final total = expectedLength;
      if (total != null && total > 0) {
        final ratio = (size / total).clamp(0.0, 1.0);
        ref
            .read(downloadServiceProvider.notifier)
            .update(
              widget.track.id,
              'DOWNLOADING',
              progress: 0.1 + (ratio * 0.8),
            );
      }
      if (expectedLength != null && size != expectedLength) return;
      stableReads = size == previousSize ? stableReads + 1 : 0;
      previousSize = size;
      // WebView2 can pause writes briefly while buffering. Requiring several
      // unchanged observations prevents importing a valid FLAC header before
      // the rest of the track has reached disk.
      if (size <= 1024 || stableReads < 5) return;
      monitor?.cancel();
      await _finalize(file);
    } finally {
      scanRunning = false;
    }
  }

  Future<void> _finalize(File file) async {
    if (cancelled) return;
    try {
      await acquisitionLog?.event('IMPORT_STARTED', {
        'path': file.path,
        'size': await file.length(),
      });
      setState(() => phase = BrowserAcquisitionPhase.verifying);
      ref
          .read(downloadServiceProvider.notifier)
          .update(widget.track.id, 'VERIFYING', progress: 0.94);
      final local = await ref
          .read(localImportServiceProvider)
          .importForTrack(file, widget.track);
      if (!mounted || cancelled) return;
      setState(() => phase = BrowserAcquisitionPhase.finalizing);
      ref
          .read(downloadServiceProvider.notifier)
          .update(widget.track.id, 'FINALIZING', progress: 0.98);
      if (!mounted || cancelled) return;
      setState(() => phase = BrowserAcquisitionPhase.ready);
      ref.read(downloadServiceProvider.notifier).complete(widget.track.id);
      await acquisitionLog?.event('ACQUISITION_COMPLETE', {
        'localPath': local.localPath,
      });
      completedTrack = local;
      if (!mounted || cancelled) return;
      _finish(local);
    } catch (error) {
      final message = error.toString().replaceFirst('FormatException: ', '');
      await acquisitionLog?.event('IMPORT_FAILED', {'error': error.toString()});
      await _handleAcquisitionFailure(message, partial: file);
    }
  }

  void _finish(TrackSummary? track) {
    if (finished) return;
    finished = true;
    widget.onFinished(track);
  }

  Future<void> _cancelAndFinish() async {
    if (cancelled || finished) return;
    cancelled = true;
    monitor?.cancel();
    automationTimer?.cancel();
    downloadStartDeadline?.cancel();
    httpCancelToken?.cancel('Cancelled by the user.');
    final output = blobOutput;
    blobOutput = null;
    if (output != null) {
      try {
        await output.close();
      } catch (_) {
        // The stream may already have closed after its final chunk.
      }
    }
    final controller = webViewController;
    webViewController = null;
    try {
      await controller?.stopLoading().timeout(const Duration(seconds: 1));
    } catch (_) {
      // The platform view may already be closing.
    }
    final partial = controlledDownloadFile;
    var partialDeleted = false;
    if (partial != null) {
      try {
        if (await partial.exists()) await partial.delete();
        partialDeleted = true;
      } catch (_) {
        // A platform download may still be releasing the file handle.
      }
    }
    final service = ref.read(downloadServiceProvider.notifier);
    _finish(null);
    if (partial != null && !partialDeleted) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        if (await partial.exists()) await partial.delete();
      } catch (_) {
        // The download has stopped; a locked file can be cleaned next launch.
      }
    }
    service.remove(widget.track.id);
  }

  void _onProviderConsole(ConsoleMessage message) {
    acquisitionLog?.event('PAGE_CONSOLE', {
      'level': message.messageLevel.toString(),
      'message': message.message,
    });
    final durationMatch = RegExp(r'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)')
        .firstMatch(message.message);
    if (durationMatch != null) {
      providerDurationSeconds =
          (int.parse(durationMatch.group(1)!) * 3600) +
          (int.parse(durationMatch.group(2)!) * 60) +
          double.parse(durationMatch.group(3)!);
    }
    final match = RegExp(r'time=(\d+):(\d+):(\d+(?:\.\d+)?)')
        .firstMatch(message.message);
    final duration = providerDurationSeconds ?? widget.track.durationSeconds;
    if (match == null || duration == null || duration <= 0) return;
    final elapsed =
        (int.parse(match.group(1)!) * 3600) +
        (int.parse(match.group(2)!) * 60) +
        double.parse(match.group(3)!);
    final conversionRatio = (elapsed / duration).clamp(0.0, 1.0);
    final progress = 0.1 + (conversionRatio * 0.75);
    if (progress - lastReportedProgress < 0.005 && progress < 0.85) return;
    lastReportedProgress = progress;
    ref
        .read(downloadServiceProvider.notifier)
        .update(widget.track.id, 'PREPARING_AUDIO', progress: progress);
  }

  Widget _buildProviderWebView() => InAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(trackUrl)),
    initialSettings: InAppWebViewSettings(
      javaScriptEnabled: true,
      useOnDownloadStart: true,
      mediaPlaybackRequiresUserGesture: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      useWideViewPort: true,
      loadWithOverviewMode: true,
    ),
    onWebViewCreated: (controller) {
      webViewController = controller;
      controller.addJavaScriptHandler(
        handlerName: 'onBlobDownloadStart',
        callback: (args) async {
          final filename = args.isNotEmpty ? args[0] as String? : null;
          return _startChunkedBlobDownload(filename);
        },
      );
      controller.addJavaScriptHandler(
        handlerName: 'onBlobDownloadChunk',
        callback: (args) =>
            args.isEmpty ? false : _appendChunkedBlob(args.first as String),
      );
      controller.addJavaScriptHandler(
        handlerName: 'onBlobDownloadEnd',
        callback: (_) => _finishChunkedBlobDownload(),
      );
      acquisitionLog?.event('WEBVIEW_CREATED', {'url': trackUrl});
    },
    onLoadStart: (_, url) =>
        acquisitionLog?.event('NAVIGATION_STARTED', {'url': _safeUrl(url)}),
    onLoadStop: (controller, url) async {
      if (cancelled) return;
      await acquisitionLog?.event('NAVIGATION_FINISHED', {
        'url': _safeUrl(url),
      });
      await controller.evaluateJavascript(
        source: '''
        (() => {
          if (window.__hihat_download_hooked) return;
          window.__hihat_download_hooked = true;

          async function handleBlobUrl(url, filename) {
            try {
              const response = await fetch(url);
              const blob = await response.blob();
              const bridge = window.flutter_inappwebview;
              if (!bridge || !bridge.callHandler) return false;
              const started = await bridge.callHandler('onBlobDownloadStart', filename);
              if (!started) return false;
              // Keep bridge messages bounded, but make them large enough to
              // avoid hundreds of expensive WebView-to-Dart round trips.
              const chunkSize = 1024 * 1024;
              for (let offset = 0; offset < blob.size; offset += chunkSize) {
                const encoded = await new Promise((resolve, reject) => {
                  const reader = new FileReader();
                  reader.onload = () => {
                    const result = String(reader.result || '');
                    const comma = result.indexOf(',');
                    resolve(comma >= 0 ? result.slice(comma + 1) : result);
                  };
                  reader.onerror = () => reject(reader.error);
                  reader.readAsDataURL(blob.slice(offset, offset + chunkSize));
                });
                const accepted = await bridge.callHandler(
                  'onBlobDownloadChunk',
                  encoded
                );
                if (!accepted) return false;
              }
              await bridge.callHandler('onBlobDownloadEnd');
              return true;
            } catch (e) {
              console.error('HiHat blob intercept error:', e);
              return false;
            }
          }

          const originalClick = HTMLAnchorElement.prototype.click;
          HTMLAnchorElement.prototype.click = function() {
            const href = this.href || this.getAttribute('href') || '';
            const download = this.getAttribute('download') || this.download;
            if (download || href.startsWith('blob:') || href.startsWith('data:')) {
              if (href.startsWith('blob:') || href.startsWith('data:')) {
                handleBlobUrl(href, download || 'download.flac');
                return;
              }
            }
            return originalClick.apply(this, arguments);
          };
        })();
      ''',
      );
      await _onLoaded(controller);
    },
    onProgressChanged: (controller, progress) {
      if (progress == 25 ||
          progress == 50 ||
          progress == 75 ||
          progress == 100) {
        acquisitionLog?.event('PAGE_PROGRESS', {'percent': progress});
      }
      if (progress >= 35 && !downloadRequested && !automationRunning) {
        unawaited(_onLoaded(controller));
      }
    },
    onConsoleMessage: (_, message) => _onProviderConsole(message),
    onReceivedError: (_, request, error) {
      acquisitionLog?.event('WEB_RESOURCE_ERROR', {
        'url': _safeUrl(request.url),
        'mainFrame': request.isForMainFrame,
        'type': error.type.toString(),
        'description': error.description,
      });
      if (request.isForMainFrame == false || !mounted) return;
      setState(() {
        phase = BrowserAcquisitionPhase.failed;
        detail =
            'Monochrome could not be loaded. Check your connection and retry.';
      });
    },
    onDownloadStarting: (_, request) => _onDownloadStarted(request),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      downloadServiceProvider.select(
        (state) => state.forTrack(widget.track.id)?.phase,
      ),
      (_, next) {
        if (next == 'CANCELLED') unawaited(_cancelAndFinish());
      },
    );
    if (!debugPreferenceLoaded) return const SizedBox.shrink();

    final transfer = ref
        .watch(downloadServiceProvider)
        .forTrack(widget.track.id);
    final isMinimized = transfer?.isMinimized ?? false;
    final isMaximized = transfer?.isMaximized ?? false;

    if (isMinimized) {
      return Offstage(
        offstage: true,
        child: FutureBuilder<void>(
          future: initialization,
          builder: (_, snapshot) =>
              snapshot.connectionState == ConnectionState.done
              ? _buildProviderWebView()
              : const SizedBox.shrink(),
        ),
      );
    }

    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 700;

    final windowWidget = Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 16,
      shadowColor: Colors.black87,
      borderRadius: isMaximized ? BorderRadius.zero : BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: isMaximized
              ? BorderRadius.zero
              : BorderRadius.circular(16),
          border: isMaximized
              ? null
              : Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.5),
                  width: 1,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: TrackArtwork(
                artworkUrl: widget.track.artworkUrl,
                size: 32,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            titleSpacing: 4,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.track.artist}  ·  Search: $searchQuery',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            actions: [
              if (debugVisible)
                IconButton(
                  tooltip: 'Copy browser debug log',
                  onPressed: acquisitionLog == null
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: acquisitionLog!.entries.join('\n'),
                            ),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Browser debug log copied.'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.bug_report_outlined, size: 20),
                ),
              if (debugVisible && phase == BrowserAcquisitionPhase.ready)
                TextButton(
                  onPressed: () => _finish(completedTrack),
                  child: const Text('Done'),
                ),
              IconButton(
                tooltip: 'Minimize to dock',
                onPressed: () {
                  ref
                      .read(downloadServiceProvider.notifier)
                      .setMinimized(widget.track.id, true);
                },
                icon: const Icon(Icons.remove_rounded, size: 20),
              ),
              IconButton(
                tooltip: isMaximized ? 'Restore window' : 'Maximize window',
                onPressed: () {
                  ref
                      .read(downloadServiceProvider.notifier)
                      .setMaximized(widget.track.id, !isMaximized);
                },
                icon: Icon(
                  isMaximized
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: 'Cancel acquisition',
                onPressed: () {
                  ref
                      .read(downloadServiceProvider.notifier)
                      .cancel(widget.track.id);
                },
                icon: const Icon(Icons.close_rounded, size: 20),
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
                          acquisitionSupervisor.reset();
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
                    return Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              phase ==
                                      BrowserAcquisitionPhase
                                          .waitingForAuthorization
                                  ? 'The provider browser is ready for verification.'
                                  : 'Searching and acquiring in Monochrome…',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ),
                        Positioned.fill(child: _buildProviderWebView()),
                      ],
                    );
                  },
                ),
              ),
              if (debugVisible) _BrowserDebugStrip(log: acquisitionLog),
            ],
          ),
        ),
      ),
    );

    if (isMaximized) {
      return windowWidget;
    }

    final windowWidth = (screenSize.width * (isCompact ? 0.95 : 0.75)).clamp(
      360.0,
      920.0,
    );
    final windowHeight = (screenSize.height * (isCompact ? 0.88 : 0.75)).clamp(
      420.0,
      720.0,
    );

    return Material(
      color: Colors.black54,
      child: Center(
        child: SizedBox(
          width: windowWidth,
          height: windowHeight,
          child: windowWidget,
        ),
      ),
    );
  }
}

class _BrowserDebugStrip extends StatelessWidget {
  const _BrowserDebugStrip({required this.log});

  final BrowserAcquisitionLog? log;

  @override
  Widget build(BuildContext context) {
    final entries = log?.entries ?? const <String>[];
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Semantics(
        liveRegion: true,
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.bug_report_outlined),
          title: Text('Debug trace · ${entries.length} events'),
          subtitle: Text(
            entries.isEmpty ? 'Preparing log file…' : entries.last,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: 'Copy complete trace',
            onPressed: entries.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: '${entries.join('\n')}\nLOG_FILE=${log?.path}',
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Browser debug log copied.'),
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.copy_all_outlined),
          ),
        ),
      ),
    );
  }
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
