import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';

class TransferState {
  const TransferState({
    required this.trackId,
    this.phase,
    this.progress = 0,
    this.error,
    this.track,
    this.isMinimized = false,
    this.isMaximized = false,
  });

  final String trackId;
  final String? phase;
  final double progress;
  final String? error;
  final TrackSummary? track;
  final bool isMinimized;
  final bool isMaximized;

  bool get isActive => const {
    'OPENING_PROVIDER',
    'AUTH_REQUIRED',
    'MATCHING_TRACK',
    'STARTING_DOWNLOAD',
    'PREPARING_AUDIO',
    'DOWNLOADING',
    'VERIFYING',
    'FINALIZING',
  }.contains(phase);

  bool get isCompleted => phase == 'COMPLETED';
  bool get isFailed => phase == 'FAILED';
  bool get isCancelled => phase == 'CANCELLED';

  TransferState copyWith({
    String? trackId,
    String? phase,
    double? progress,
    String? error,
    TrackSummary? track,
    bool? isMinimized,
    bool? isMaximized,
  }) => TransferState(
    trackId: trackId ?? this.trackId,
    phase: phase ?? this.phase,
    progress: progress ?? this.progress,
    error: error ?? this.error,
    track: track ?? this.track,
    isMinimized: isMinimized ?? this.isMinimized,
    isMaximized: isMaximized ?? this.isMaximized,
  );
}

class DownloadsState {
  const DownloadsState({
    this.transfers = const <String, TransferState>{},
    this.focusedTrackId,
  });

  final Map<String, TransferState> transfers;
  final String? focusedTrackId;

  TransferState? forTrack(String? trackId) =>
      trackId != null ? transfers[trackId] : null;

  TransferState? get latestTransfer {
    if (focusedTrackId != null && transfers.containsKey(focusedTrackId)) {
      return transfers[focusedTrackId];
    }
    if (transfers.isEmpty) return null;
    return transfers.values.last;
  }

  // Backwards compatibility getters
  String? get trackId => latestTransfer?.trackId;
  String? get phase => latestTransfer?.phase;
  double get progress => latestTransfer?.progress ?? 0;
  String? get error => latestTransfer?.error;

  bool isTrackActive(String? trackId) => forTrack(trackId)?.isActive ?? false;

  List<TransferState> get activeTransfers =>
      transfers.values.where((t) => t.isActive).toList();

  List<TransferState> get allTransfers => transfers.values.toList();

  DownloadsState copyWith({
    Map<String, TransferState>? transfers,
    String? focusedTrackId,
  }) => DownloadsState(
    transfers: transfers ?? this.transfers,
    focusedTrackId: focusedTrackId ?? this.focusedTrackId,
  );
}

class DownloadService extends StateNotifier<DownloadsState> {
  DownloadService() : super(const DownloadsState());

  void begin(String trackId, {TrackSummary? track}) {
    final current = state.forTrack(trackId);
    if (current != null && current.isActive) {
      state = state.copyWith(focusedTrackId: trackId);
      return;
    }
    final nextTransfers = Map<String, TransferState>.from(state.transfers);
    nextTransfers[trackId] = TransferState(
      trackId: trackId,
      phase: 'OPENING_PROVIDER',
      progress: 0.02,
      track: track ?? current?.track,
      isMinimized: true,
    );
    state = DownloadsState(transfers: nextTransfers, focusedTrackId: trackId);
  }

  void update(
    String trackId,
    String phase, {
    double progress = 0,
    TrackSummary? track,
  }) {
    final current = state.forTrack(trackId);
    final normalizedProgress = progress.clamp(0.0, 1.0);
    // Provider callbacks can arrive out of order (for example, conversion
    // console output after the file download callback). Never let an active
    // transfer's bar jump backwards.
    final stableProgress = current != null && current.isActive
        ? normalizedProgress.clamp(current.progress, 1.0)
        : normalizedProgress;
    final nextTransfers = Map<String, TransferState>.from(state.transfers);
    nextTransfers[trackId] = TransferState(
      trackId: trackId,
      phase: phase,
      progress: stableProgress,
      error: null,
      track: track ?? current?.track,
      isMinimized: current?.isMinimized ?? false,
      isMaximized: current?.isMaximized ?? false,
    );
    state = state.copyWith(transfers: nextTransfers);
  }

  void fail(String trackId, String message, {TrackSummary? track}) {
    final current = state.forTrack(trackId);
    final nextTransfers = Map<String, TransferState>.from(state.transfers);
    nextTransfers[trackId] = TransferState(
      trackId: trackId,
      phase: 'FAILED',
      error: message,
      track: track ?? current?.track,
      isMinimized: current?.isMinimized ?? false,
      isMaximized: current?.isMaximized ?? false,
    );
    state = state.copyWith(transfers: nextTransfers);
  }

  void complete(String trackId, {TrackSummary? track}) {
    final current = state.forTrack(trackId);
    final nextTransfers = Map<String, TransferState>.from(state.transfers);
    nextTransfers[trackId] = TransferState(
      trackId: trackId,
      phase: 'COMPLETED',
      progress: 1,
      track: track ?? current?.track,
      isMinimized: current?.isMinimized ?? false,
      isMaximized: current?.isMaximized ?? false,
    );
    state = state.copyWith(transfers: nextTransfers);
  }

  void cancel(String trackId) {
    final current = state.forTrack(trackId);
    if (current == null) return;
    final nextTransfers = Map<String, TransferState>.from(state.transfers);
    nextTransfers[trackId] = TransferState(
      trackId: trackId,
      phase: 'CANCELLED',
      track: current.track,
      isMinimized: current.isMinimized,
      isMaximized: current.isMaximized,
    );
    state = state.copyWith(transfers: nextTransfers);
  }

  void setMinimized(String trackId, bool minimized) {
    final current = state.forTrack(trackId);
    if (current == null) return;
    final nextTransfers = Map<String, TransferState>.from(state.transfers);
    nextTransfers[trackId] = current.copyWith(isMinimized: minimized);
    state = state.copyWith(transfers: nextTransfers);
  }

  void setMaximized(String trackId, bool maximized) {
    final current = state.forTrack(trackId);
    if (current == null) return;
    final nextTransfers = Map<String, TransferState>.from(state.transfers);
    nextTransfers[trackId] = current.copyWith(isMaximized: maximized);
    state = state.copyWith(transfers: nextTransfers);
  }

  void focus(String trackId) {
    final current = state.forTrack(trackId);
    if (current == null) return;
    final nextTransfers = Map<String, TransferState>.from(state.transfers);
    nextTransfers[trackId] = current.copyWith(isMinimized: false);
    state = state.copyWith(transfers: nextTransfers, focusedTrackId: trackId);
  }

  void remove(String trackId) {
    final nextTransfers = Map<String, TransferState>.from(state.transfers)
      ..remove(trackId);
    state = DownloadsState(
      transfers: nextTransfers,
      focusedTrackId: state.focusedTrackId == trackId
          ? null
          : state.focusedTrackId,
    );
  }
}

final downloadServiceProvider =
    StateNotifierProvider<DownloadService, DownloadsState>(
      (ref) => DownloadService(),
    );
