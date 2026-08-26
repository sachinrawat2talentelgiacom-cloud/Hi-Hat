import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import 'flac_metadata.dart';
import 'library_service.dart';

const libraryFolderPreferenceKey = 'libraryFolderPath';
const libraryFolderUriPreferenceKey = 'libraryFolderUri';
const libraryFolderNamePreferenceKey = 'libraryFolderName';

class LibraryScanResult {
  const LibraryScanResult({required this.found, required this.added});

  final int found;
  final int added;
}

class LibraryFolderService {
  LibraryFolderService(this.ref);

  final Ref ref;

  Future<String?> configuredPath() async {
    final preferences = await SharedPreferences.getInstance();
    if (Platform.isAndroid) {
      final uri = preferences.getString(libraryFolderUriPreferenceKey)?.trim();
      return uri == null || uri.isEmpty ? null : uri;
    }
    final value = preferences.getString(libraryFolderPreferenceKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<String?> configurationLabel() async {
    final preferences = await SharedPreferences.getInstance();
    if (Platform.isAndroid) {
      return preferences.getString(libraryFolderNamePreferenceKey);
    }
    return configuredPath();
  }

  Future<Directory> libraryRoot() async {
    final documents = await getApplicationDocumentsDirectory();
    if (!Platform.isAndroid) {
      final configured = await configuredPath();
      if (configured != null) return Directory(configured);
    }
    return Directory(p.join(documents.path, 'Music'));
  }

  Future<String?> chooseFolder() async {
    if (Platform.isAndroid) {
      final selected = await Saf().pickDirectory();
      if (selected == null) return null;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(libraryFolderUriPreferenceKey, selected.uri);
      await preferences.setString(
        libraryFolderNamePreferenceKey,
        selected.name,
      );
      return selected.name;
    }
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose your Hi Hat music folder',
    );
    if (selected == null) return null;
    final folder = Directory(selected);
    await folder.create(recursive: true);
    await _verifyWritable(folder);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(libraryFolderPreferenceKey, folder.path);
    return folder.path;
  }

  Future<LibraryScanResult> scanConfiguredFolder() async {
    final configured = await configuredPath();
    if (configured == null) {
      return const LibraryScanResult(found: 0, added: 0);
    }
    if (Platform.isAndroid) return _scanAndroidFolder(configured);
    final folder = Directory(configured);
    if (!await folder.exists()) {
      throw FileSystemException('The selected music folder is unavailable.');
    }

    var found = 0;
    var added = 0;
    await for (final entity in folder.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.flac')) {
        continue;
      }
      found++;
      try {
        final metadata = await FlacMetadataReader.read(entity);
        final bytes = await entity.readAsBytes();
        final digest = sha256.convert(bytes).toString();
        final database = ref.read(databaseProvider);
        final duplicate = await database.findBySha256(digest);
        if (duplicate != null) {
          if (duplicate.localPath != entity.path) {
            await database.updateLocalPath(duplicate.id, entity.path);
          }
          continue;
        }
        await database.saveTrack(
          TracksCompanion.insert(
            id: 'local:$digest',
            provider: 'local',
            providerTrackId: digest,
            title: metadata.title ?? p.basenameWithoutExtension(entity.path),
            artist: metadata.artist ?? 'Unknown artist',
            album: Value(metadata.album),
            localPath: entity.path,
            sha256: digest,
            codec: const Value('FLAC'),
            bitDepth: Value(metadata.bitDepth),
            sampleRate: Value(metadata.sampleRate),
            channels: Value(metadata.channels),
            durationSeconds: Value(metadata.durationSeconds),
            fileSize: bytes.length,
          ),
        );
        added++;
      } on FormatException {
        // A damaged or mislabeled FLAC does not enter the verified library.
      } on FileSystemException {
        // Keep scanning if one file is temporarily unreadable.
      }
    }
    return LibraryScanResult(found: found, added: added);
  }

  Future<void> persistDownloadedFile(
    File source, {
    required String artist,
    required String album,
    required String title,
  }) async {
    if (!Platform.isAndroid) return;
    final rootUri = await configuredPath();
    if (rootUri == null) return;
    final saf = Saf();
    final destination = await saf.mkdirp(rootUri, [artist, album]);
    await saf.pasteLocalFile(
      source.path,
      destination.uri,
      '$title.flac',
      'audio/flac',
      overwrite: true,
    );
  }

  Future<LibraryScanResult> _scanAndroidFolder(String rootUri) async {
    final saf = Saf();
    final cacheRoot = await libraryRoot();
    await cacheRoot.create(recursive: true);
    var found = 0;
    var added = 0;
    await for (final entry in saf.walk(rootUri)) {
      if (entry.file.isDir ||
          !entry.file.name.toLowerCase().endsWith('.flac')) {
        continue;
      }
      found++;
      final temporary = File(
        p.join(
          cacheRoot.path,
          '.scan-${DateTime.now().microsecondsSinceEpoch}.flac',
        ),
      );
      try {
        await saf.copyToLocalFile(entry.file.uri, temporary.path);
        final metadata = await FlacMetadataReader.read(temporary);
        final bytes = await temporary.readAsBytes();
        final digest = sha256.convert(bytes).toString();
        final database = ref.read(databaseProvider);
        final duplicate = await database.findBySha256(digest);
        if (duplicate != null && await File(duplicate.localPath).exists()) {
          continue;
        }
        final artist = metadata.artist ?? 'Unknown artist';
        final album = metadata.album ?? 'Singles';
        final folder = Directory(
          p.join(
            cacheRoot.path,
            _safePathSegment(artist),
            _safePathSegment(album),
          ),
        );
        await folder.create(recursive: true);
        final local = File(
          p.join(
            folder.path,
            '${_safePathSegment(metadata.title ?? p.basenameWithoutExtension(entry.file.name))}.flac',
          ),
        );
        if (await local.exists()) await local.delete();
        await temporary.rename(local.path);
        await database.saveTrack(
          TracksCompanion.insert(
            id: duplicate?.id ?? 'local:$digest',
            provider: duplicate?.provider ?? 'local',
            providerTrackId: duplicate?.providerTrackId ?? digest,
            title:
                metadata.title ?? p.basenameWithoutExtension(entry.file.name),
            artist: artist,
            album: Value(metadata.album),
            localPath: local.path,
            sha256: digest,
            codec: const Value('FLAC'),
            bitDepth: Value(metadata.bitDepth),
            sampleRate: Value(metadata.sampleRate),
            channels: Value(metadata.channels),
            durationSeconds: Value(metadata.durationSeconds),
            fileSize: bytes.length,
          ),
        );
        added++;
      } on FormatException {
        // Ignore damaged files and continue scanning the granted folder.
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
    }
    return LibraryScanResult(found: found, added: added);
  }

  static String _safePathSegment(String value) =>
      value.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();

  Future<void> _verifyWritable(Directory folder) async {
    final probe = File(
      p.join(
        folder.path,
        '.hihat-write-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    try {
      await probe.writeAsString('Hi Hat');
    } finally {
      if (await probe.exists()) await probe.delete();
    }
  }
}

final libraryFolderServiceProvider = Provider(LibraryFolderService.new);
