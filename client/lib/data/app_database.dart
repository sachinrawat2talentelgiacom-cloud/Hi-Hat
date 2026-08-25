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
  IntColumn get fileSize => integer()();
  DateTimeColumn get downloadedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Tracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'hi_hat'));

  @override
  int get schemaVersion => 1;

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
}
