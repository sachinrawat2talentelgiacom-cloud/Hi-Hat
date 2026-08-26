import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/app_database.dart';
import '../models/track.dart';
import 'flac_metadata.dart';
import 'library_service.dart';

class LocalImportService {
  LocalImportService(this.ref) : _database = null, _libraryRoot = null;
  LocalImportService.forTesting(this._database, this._libraryRoot) : ref = null;
  final Ref? ref;
  final AppDatabase? _database;
  final Future<Directory> Function()? _libraryRoot;

  Future<TrackSummary> importForTrack(
    File source,
    TrackSummary requested,
  ) async {
    final metadata = await FlacMetadataReader.read(source);
    if (metadata.durationSeconds <= 0) {
      throw const FormatException(
        'The downloaded FLAC has no playable duration.',
      );
    }
    final expected = requested.durationSeconds;
    if (expected != null &&
        (metadata.durationSeconds - expected).abs() >
            (expected * 0.08).clamp(5, 12)) {
      throw const FormatException(
        'The downloaded FLAC is not the complete requested track.',
      );
    }

    final bytes = await source.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    final AppDatabase database = _database ?? ref!.read(databaseProvider);
    final duplicate = await database.findBySha256(digest);
    if (duplicate != null && await File(duplicate.localPath).exists()) {
      return requested.copyWith(
        localPath: duplicate.localPath,
        quality: AudioQuality(
          codec: duplicate.codec,
          lossless: duplicate.codec?.toUpperCase() == 'FLAC',
          bitDepth: duplicate.bitDepth,
          sampleRate: duplicate.sampleRate,
        ),
      );
    }

    final root =
        await (_libraryRoot?.call() ?? getApplicationDocumentsDirectory());
    final title = metadata.title ?? requested.title;
    final artist = metadata.artist ?? requested.artist;
    final album = metadata.album ?? requested.album;
    final folder = Directory(
      p.join(
        root.path,
        'Music',
        safePathSegment(artist),
        safePathSegment(album ?? 'Singles'),
      ),
    );
    await folder.create(recursive: true);
    final finalPath = p.join(folder.path, '${safePathSegment(title)}.flac');
    final partPath = '$finalPath.part';
    await File(partPath).writeAsBytes(bytes, flush: true);
    await FlacMetadataReader.read(File(partPath));
    final finalFile = await File(partPath).rename(finalPath);
    final quality = AudioQuality(
      codec: 'FLAC',
      lossless: true,
      bitDepth: metadata.bitDepth,
      sampleRate: metadata.sampleRate,
      label: 'verified',
    );
    await database.saveTrack(
      TracksCompanion.insert(
        id: requested.id,
        provider: requested.provider,
        providerTrackId: requested.providerTrackId,
        title: title,
        artist: artist,
        album: Value(album),
        artworkUrl: Value(requested.artworkUrl),
        localPath: finalFile.path,
        sha256: digest,
        codec: const Value('FLAC'),
        bitDepth: Value(metadata.bitDepth),
        sampleRate: Value(metadata.sampleRate),
        channels: Value(metadata.channels),
        durationSeconds: Value(metadata.durationSeconds),
        fileSize: bytes.length,
      ),
    );
    return TrackSummary(
      id: requested.id,
      provider: requested.provider,
      providerTrackId: requested.providerTrackId,
      title: title,
      artist: artist,
      album: album,
      artworkUrl: requested.artworkUrl,
      durationSeconds: metadata.durationSeconds,
      explicit: requested.explicit,
      quality: quality,
      localPath: finalFile.path,
    );
  }

  static String safePathSegment(String value) =>
      value.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
}

final localImportServiceProvider = Provider(LocalImportService.new);
