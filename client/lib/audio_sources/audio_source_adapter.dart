import 'dart:async';

enum SourceHealthStatus {
  healthy,
  degraded,
  unavailable,
  authRequired,
  notConfigured,
}

class SourceHealth {
  const SourceHealth(this.status, {this.message, this.checkedAt});
  final SourceHealthStatus status;
  final String? message;
  final DateTime? checkedAt;
}

class SearchTrackRequest {
  const SearchTrackRequest({
    required this.query,
    this.title,
    this.artist,
    this.album,
    this.isrc,
    this.expectedDurationSeconds,
  });

  final String query;
  final String? title;
  final String? artist;
  final String? album;
  final String? isrc;
  final double? expectedDurationSeconds;
}

class SourceTrackCandidate {
  const SourceTrackCandidate({
    required this.source,
    required this.sourceTrackId,
    required this.title,
    required this.artist,
    this.album,
    this.isrc,
    this.durationSeconds,
    this.artworkUrl,
    this.license,
    this.attribution,
    this.downloadAllowed = false,
    this.flacPossible = false,
    this.metadata = const {},
  });

  final String source;
  final String sourceTrackId;
  final String title;
  final String artist;
  final String? album;
  final String? isrc;
  final double? durationSeconds;
  final String? artworkUrl;
  final String? license;
  final String? attribution;
  final bool downloadAllowed;
  final bool flacPossible;
  final Map<String, Object?> metadata;
}

class ResolvedAudioCandidate {
  const ResolvedAudioCandidate({
    required this.track,
    required this.uri,
    required this.permissionConfirmed,
    this.contentLength,
  });

  final SourceTrackCandidate track;
  final Uri uri;
  final bool permissionConfirmed;
  final int? contentLength;
}

class CancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw const SourceCancelledException();
  }
}

class SourceCancelledException implements Exception {
  const SourceCancelledException();
}

abstract interface class AudioSourceAdapter {
  String get id;
  Duration get searchTimeout;
  Future<SourceHealth> healthCheck();
  Future<List<SourceTrackCandidate>> search(
    SearchTrackRequest request,
    CancellationToken token,
  );
  Future<ResolvedAudioCandidate?> resolveFlac(
    SourceTrackCandidate candidate,
    CancellationToken token,
  );
}
