import 'audio_source_adapter.dart';

class CandidateMatcher {
  static int score(SearchTrackRequest request, SourceTrackCandidate candidate) {
    var score = 0;
    final requestedIsrc = normalize(request.isrc);
    if (requestedIsrc.isNotEmpty &&
        requestedIsrc == normalize(candidate.isrc)) {
      score += 100;
    }
    if (normalize(request.title).isNotEmpty &&
        _matches(request.title, candidate.title)) {
      score += 40;
    }
    if (normalize(request.artist).isNotEmpty &&
        _matches(request.artist, candidate.artist)) {
      score += 40;
    }
    if (normalize(request.album).isNotEmpty &&
        _matches(request.album, candidate.album)) {
      score += 10;
    }
    final expected = request.expectedDurationSeconds;
    final actual = candidate.durationSeconds;
    if (expected != null && actual != null) {
      final difference = (expected - actual).abs();
      if (difference <= 3) {
        score += 10;
      } else if (difference <= 7) {
        score += 5;
      }
    }
    return score;
  }

  static bool isPlausible(
    SearchTrackRequest request,
    SourceTrackCandidate candidate,
  ) {
    if (request.title != null && !_matches(request.title, candidate.title)) {
      return false;
    }
    if (request.artist != null && !_matches(request.artist, candidate.artist)) {
      return false;
    }
    return true;
  }

  static String logicalKey(SourceTrackCandidate candidate) {
    final isrc = normalize(candidate.isrc);
    if (isrc.isNotEmpty) return 'isrc:$isrc';
    final durationBucket = candidate.durationSeconds == null
        ? 'unknown'
        : (candidate.durationSeconds! / 5).round().toString();
    return '${normalize(candidate.title)}|${normalize(candidate.artist)}|$durationBucket';
  }

  static String normalize(String? value) => (value ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _matches(String? expected, String? actual) {
    final left = normalize(expected);
    return left.isEmpty || left == normalize(actual);
  }
}
