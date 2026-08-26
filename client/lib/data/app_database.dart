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

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Tracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'hi_hat'));
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
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
