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
  LocalImportService(this.ref);
  final Ref ref;

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
    final database = ref.read(databaseProvider);
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

    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(
      p.join(
        root.path,
        'Music',
        safePathSegment(requested.artist),
        safePathSegment(requested.album ?? 'Singles'),
      ),
    );
    await folder.create(recursive: true);
    final finalPath = p.join(
      folder.path,
      '${safePathSegment(requested.title)}.flac',
    );
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
        title: requested.title,
        artist: requested.artist,
        album: Value(requested.album),
        artworkUrl: Value(requested.artworkUrl),
        localPath: finalFile.path,
        sha256: digest,
        codec: const Value('FLAC'),
        bitDepth: Value(metadata.bitDepth),
        sampleRate: Value(metadata.sampleRate),
        fileSize: bytes.length,
      ),
    );
    return requested.copyWith(localPath: finalFile.path, quality: quality);
  }

  static String safePathSegment(String value) =>
      value.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
}

final localImportServiceProvider = Provider(LocalImportService.new);
