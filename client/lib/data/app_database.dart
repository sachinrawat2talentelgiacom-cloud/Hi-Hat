import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get provider => text()();
  TextColumn get providerTrackId => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  TextColumn get localPath => text()();
  TextColumn get sha256 => text()();
  TextColumn get codec => text().nullable()();
  IntColumn get bitDepth => integer().nullable()();
  IntColumn get sampleRate => integer().nullable()();
  IntColumn get channels => integer().nullable()();
  RealColumn get durationSeconds => real().nullable()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get downloadedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get validatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get year => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get bpm => integer().nullable()();
  TextColumn get key => text().nullable()();
  TextColumn get isrc => text().nullable()();
  TextColumn get copyright => text().nullable()();
  RealColumn get replayGain => real().nullable()();
  RealColumn get peak => real().nullable()();
  TextColumn get version => text().nullable()();
  TextColumn get audioQualityLabel => text().nullable()();
  TextColumn get vibrantColor => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Tracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'hi_hat'));
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      final existing = (await customSelect(
        'PRAGMA table_info(tracks)',
      ).get()).map((row) => row.read<String>('name')).toSet();
      if (!existing.contains('channels')) {
        await migrator.addColumn(tracks, tracks.channels);
      }
      if (!existing.contains('duration_seconds')) {
        await migrator.addColumn(tracks, tracks.durationSeconds);
      }
      if (!existing.contains('validated_at')) {
        await customStatement(
          'ALTER TABLE tracks ADD COLUMN validated_at INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!existing.contains('year')) {
        await migrator.addColumn(tracks, tracks.year);
      }
      if (!existing.contains('track_number')) {
        await migrator.addColumn(tracks, tracks.trackNumber);
      }
      if (!existing.contains('disc_number')) {
        await migrator.addColumn(tracks, tracks.discNumber);
      }
      if (!existing.contains('genre')) {
        await migrator.addColumn(tracks, tracks.genre);
      }
      if (!existing.contains('bpm')) {
        await migrator.addColumn(tracks, tracks.bpm);
      }
      if (!existing.contains('key')) {
        await migrator.addColumn(tracks, tracks.key);
      }
      if (!existing.contains('isrc')) {
        await migrator.addColumn(tracks, tracks.isrc);
      }
      if (!existing.contains('copyright')) {
        await migrator.addColumn(tracks, tracks.copyright);
      }
      if (!existing.contains('replay_gain')) {
        await migrator.addColumn(tracks, tracks.replayGain);
      }
      if (!existing.contains('peak')) {
        await migrator.addColumn(tracks, tracks.peak);
      }
      if (!existing.contains('version')) {
        await migrator.addColumn(tracks, tracks.version);
      }
      if (!existing.contains('audio_quality_label')) {
        await migrator.addColumn(tracks, tracks.audioQualityLabel);
      }
      if (!existing.contains('vibrant_color')) {
        await migrator.addColumn(tracks, tracks.vibrantColor);
      }
    },
  );

  Stream<List<Track>> watchLibrary() =>
      (select(tracks)..orderBy([
            (row) => OrderingTerm(
              expression: row.downloadedAt,
              mode: OrderingMode.desc,
            ),
          ]))
          .watch();

  Future<List<Track>> searchLibrary(String query) {
    final pattern = '%${query.trim()}%';
    return (select(tracks)
          ..where(
            (row) =>
                row.title.like(pattern) |
                row.artist.like(pattern) |
                row.album.like(pattern),
          )
          ..orderBy([
            (row) => OrderingTerm(
              expression: row.downloadedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<Track?> findByProviderId(String providerTrackId) =>
      (select(tracks)
            ..where((row) => row.providerTrackId.equals(providerTrackId)))
          .getSingleOrNull();

  Future<Track?> findBySha256(String digest) => (select(
    tracks,
  )..where((row) => row.sha256.equals(digest))).getSingleOrNull();

  Future<void> saveTrack(TracksCompanion value) =>
      into(tracks).insertOnConflictUpdate(value);

  Future<void> updateLocalPath(String id, String localPath) =>
      (update(tracks)..where((row) => row.id.equals(id))).write(
        TracksCompanion(localPath: Value(localPath)),
      );
}
