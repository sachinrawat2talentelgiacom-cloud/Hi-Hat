import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../models/track.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

TrackSummary localTrackSummary(Track row) => TrackSummary(
  id: row.id,
  provider: 'local',
  providerTrackId: row.providerTrackId,
  title: row.title,
  artist: row.artist,
  album: row.album,
  artworkUrl: row.artworkUrl,
  localPath: row.localPath,
  quality: AudioQuality(
    codec: row.codec,
    lossless: row.codec?.toUpperCase() == 'FLAC',
    bitDepth: row.bitDepth,
    sampleRate: row.sampleRate,
  ),
);

final libraryProvider = StreamProvider<List<TrackSummary>>((ref) {
  return ref
      .watch(databaseProvider)
      .watchLibrary()
      .map((rows) => rows.map(localTrackSummary).toList(growable: false));
});
