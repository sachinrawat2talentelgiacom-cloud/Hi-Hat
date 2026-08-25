import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  DownloadService() : super(const TransferState());

  void begin(String trackId) {
    if (state.trackId == trackId && _active(state.phase)) return;
    state = TransferState(trackId: trackId, phase: 'OPENING_PROVIDER');
  }

  void update(String trackId, String phase, {double progress = 0}) {
    state = TransferState(
      trackId: trackId,
      phase: phase,
      progress: progress.clamp(0, 1),
    );
  }

  void fail(String trackId, String message) {
    state = TransferState(trackId: trackId, phase: 'FAILED', error: message);
  }

  void complete(String trackId) {
    state = TransferState(trackId: trackId, phase: 'COMPLETED', progress: 1);
  }

  void cancel(String trackId) {
    state = TransferState(trackId: trackId, phase: 'CANCELLED');
  }

  static bool _active(String? phase) => const {
    'OPENING_PROVIDER',
    'AUTH_REQUIRED',
    'MATCHING_TRACK',
    'STARTING_DOWNLOAD',
    'DOWNLOADING',
    'VERIFYING',
    'FINALIZING',
  }.contains(phase);
}

final downloadServiceProvider =
    StateNotifierProvider<DownloadService, TransferState>(
      (ref) => DownloadService(),
    );
