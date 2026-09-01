import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romanize/romanize.dart';

import '../models/track.dart';
import 'lyrics_service.dart';

class LyricsRomanizationService {
  static Future<void>? _initialization;

  Future<String> romanize(String lyrics) async {
    await (_initialization ??= TextRomanizer.ensureInitialized());
    final romanizer = TextRomanizer.forLanguage('japanese');
    return lyrics.split('\n').map(romanizer.romanize).join('\n').trim();
  }
}

final lyricsRomanizationServiceProvider = Provider(
  (ref) => LyricsRomanizationService(),
);

final romajiLyricsProvider = FutureProvider.family<String?, TrackSummary>((
  ref,
  track,
) async {
  final lyrics = await ref.read(lyricsServiceProvider).fetch(track);
  if (lyrics == null || lyrics.plain.trim().isEmpty) return null;
  return ref.read(lyricsRomanizationServiceProvider).romanize(lyrics.plain);
});
