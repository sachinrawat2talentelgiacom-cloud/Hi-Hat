import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../models/track.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

TrackSummary localTrackSummary(Track row) {
  final bitrate = row.durationSeconds != null && row.durationSeconds! > 0
      ? ((row.fileSize * 8) / row.durationSeconds!).round()
      : null;
  return TrackSummary(
    id: row.id,
    provider: row.provider,
    providerTrackId: row.providerTrackId,
    title: row.title,
    artist: row.artist,
    album: row.album,
    artworkUrl: row.artworkUrl,
    localPath: row.localPath,
    durationSeconds: row.durationSeconds,
    fileSize: row.fileSize,
    year: row.year,
    trackNumber: row.trackNumber,
    discNumber: row.discNumber,
    genre: row.genre,
    bpm: row.bpm,
    key: row.key,
    isrc: row.isrc,
    copyright: row.copyright,
    replayGain: row.replayGain,
    peak: row.peak,
    version: row.version,
    vibrantColor: row.vibrantColor,
    quality: AudioQuality(
      codec: row.codec ?? 'FLAC',
      lossless: row.codec?.toUpperCase() == 'FLAC' || row.codec == null,
      bitDepth: row.bitDepth,
      sampleRate: row.sampleRate,
      channels: row.channels,
      bitrate: bitrate,
      label: row.audioQualityLabel ?? 'FLAC',
    ),
  );
}

final libraryProvider = StreamProvider<List<TrackSummary>>((ref) {
  return ref
      .watch(databaseProvider)
      .watchLibrary()
      .map((rows) => rows.map(localTrackSummary).toList(growable: false));
});
