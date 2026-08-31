import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/data/app_database.dart';
import 'package:hi_hat/models/track.dart';
import 'package:hi_hat/services/flac_metadata.dart';
import 'package:hi_hat/services/local_import_service.dart';

void main() {
  test('finalizes a full FLAC and persists measured metadata', () async {
    final fixture = File('../backend/tests/assets/player_test.flac');
    final temporary = await Directory.systemTemp.createTemp('hihat-import-');
    final databaseFile = File('${temporary.path}/library.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(databaseFile));
    addTearDown(() async {
      await database.close();
      await temporary.delete(recursive: true);
    });

    final service = LocalImportService.forTesting(
      database,
      () async => temporary,
    );
    const requested = TrackSummary(
      id: 'fixture:gapless-1',
      provider: 'fixture',
      providerTrackId: 'gapless-1',
      title: 'Gapless FLAC #1',
      artist: 'Me',
      album: 'Fallback album',
      durationSeconds: 10,
    );

    final local = await service.importForTrack(fixture, requested);
    final row = await database.findByProviderId('gapless-1');

    expect(File(local.localPath!).existsSync(), isTrue);
    expect(local.title, 'Gapless FLAC #1');
    expect(local.artist, 'Me');
    expect(local.album, 'Exaile Test Files');
    expect(row, isNotNull);
    expect(row!.codec, 'FLAC');
    expect(row.sampleRate, 44100);
    expect(row.bitDepth, 16);
    expect(row.channels, 1);
    expect(row.durationSeconds, closeTo(10, 0.01));
    expect(row.fileSize, 271801);
    expect(row.sha256, hasLength(64));

    await database.close();
    database = AppDatabase.forTesting(NativeDatabase(databaseFile));
    final persisted = await database.findByProviderId('gapless-1');
    expect(persisted, isNotNull);
    expect(File(persisted!.localPath).existsSync(), isTrue);
    expect(persisted.title, 'Gapless FLAC #1');
  });

  test('rejects a same-duration FLAC with the wrong title and artist', () {
    const requested = TrackSummary(
      id: 'catalog:runaway',
      provider: 'catalog',
      providerTrackId: 'runaway',
      title: 'Runaway',
      artist: 'Kanye West, Pusha T',
      durationSeconds: 323,
    );
    const wrongMetadata = FlacMetadata(
      title: 'Kanye West (Runaway)',
      artist: 'Nikita Kondrashev',
      sampleRate: 44100,
      bitDepth: 24,
      channels: 2,
      durationSeconds: 323,
    );

    expect(
      () => LocalImportService.validateTrackIdentity(wrongMetadata, requested),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Track identity mismatch'),
        ),
      ),
    );
  });
}
