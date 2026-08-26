import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/data/app_database.dart';
import 'package:hi_hat/services/library_folder_service.dart';
import 'package:hi_hat/services/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scans every FLAC below the selected library folder', () async {
    final temporary = await Directory.systemTemp.createTemp('hihat-library-');
    final musicFolder = Directory('${temporary.path}/chosen')..createSync();
    final nestedFolder = Directory('${musicFolder.path}/Artist/Album')
      ..createSync(recursive: true);
    await File('../backend/tests/assets/player_test.flac')
        .copy('${nestedFolder.path}/Track.flac');
    SharedPreferences.setMockInitialValues({
      libraryFolderPreferenceKey: musicFolder.path,
    });
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
      await temporary.delete(recursive: true);
    });

    final result = await container
        .read(libraryFolderServiceProvider)
        .scanConfiguredFolder();
    final rows = await database.watchLibrary().first;

    expect(result.found, 1);
    expect(result.added, 1);
    expect(rows, hasLength(1));
    expect(rows.single.title, 'Gapless FLAC #1');
    expect(rows.single.localPath, endsWith('Track.flac'));
  });

  test('rescanning does not duplicate an indexed track', () async {
    final temporary = await Directory.systemTemp.createTemp('hihat-library-');
    await File('../backend/tests/assets/player_test.flac')
        .copy('${temporary.path}/Track.flac');
    SharedPreferences.setMockInitialValues({
      libraryFolderPreferenceKey: temporary.path,
    });
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
      await temporary.delete(recursive: true);
    });

    final service = container.read(libraryFolderServiceProvider);
    await service.scanConfiguredFolder();
    final result = await service.scanConfiguredFolder();
    final rows = await database.watchLibrary().first;

    expect(result.found, 1);
    expect(result.added, 0);
    expect(rows, hasLength(1));
  });
}
