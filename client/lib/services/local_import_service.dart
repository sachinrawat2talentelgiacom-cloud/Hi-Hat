import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../data/app_database.dart';
import '../models/track.dart';
import 'flac_metadata.dart';
import 'file_integrity.dart';
import 'library_folder_service.dart';
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

    final fileSize = await source.length();
    final digest = await sha256File(source);
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
        await (_libraryRoot?.call() ??
            ref!.read(libraryFolderServiceProvider).libraryRoot());
    final title = metadata.title ?? requested.title;
    final artist = metadata.artist ?? requested.artist;
    final album = metadata.album ?? requested.album;
    final folder = Directory(
      p.join(
        root.path,
        safePathSegment(artist),
        safePathSegment(album ?? 'Singles'),
      ),
    );
    await folder.create(recursive: true);
    final finalPath = p.join(folder.path, '${safePathSegment(title)}.flac');
    final partPath = '$finalPath.part';
    final partFile = File(partPath);
    if (await partFile.exists()) await partFile.delete();
    await source.copy(partPath);
    await FlacMetadataReader.read(File(partPath));
    final finalFile = await File(partPath).rename(finalPath);
    await ref
        ?.read(libraryFolderServiceProvider)
        .persistDownloadedFile(
          finalFile,
          artist: safePathSegment(artist),
          album: safePathSegment(album ?? 'Singles'),
          title: safePathSegment(title),
        );
    String? artworkPath = requested.artworkUrl;
    if (artworkPath == null && metadata.picture != null) {
      artworkPath = await LibraryFolderService.saveCoverArt(
        digest,
        metadata.picture!.data,
        metadata.picture!.mimeType,
      );
    }

    final quality = AudioQuality(
      codec: 'FLAC',
      lossless: true,
      bitDepth: metadata.bitDepth,
      sampleRate: metadata.sampleRate,
      channels: metadata.channels,
      bitrate: metadata.durationSeconds > 0
          ? ((fileSize * 8) / metadata.durationSeconds).round()
          : null,
      label: 'verified',
    );
    final year = metadata.year ?? requested.year;
    final trackNumber = metadata.trackNumber ?? requested.trackNumber;
    final discNumber = metadata.discNumber ?? requested.discNumber;
    final genre = metadata.genre ?? requested.genre;
    final bpm = metadata.bpm ?? requested.bpm;
    final key = metadata.key ?? requested.key;
    final isrc = metadata.isrc ?? requested.isrc;
    final copyright = metadata.copyright ?? requested.copyright;
    final replayGain = metadata.replayGain ?? requested.replayGain;
    final peak = metadata.peak ?? requested.peak;
    final version = metadata.version ?? requested.version;

    await database.saveTrack(
      TracksCompanion.insert(
        id: requested.id,
        provider: requested.provider,
        providerTrackId: requested.providerTrackId,
        title: title,
        artist: artist,
        album: Value(album),
        artworkUrl: Value(artworkPath),
        localPath: finalFile.path,
        sha256: digest,
        codec: const Value('FLAC'),
        bitDepth: Value(metadata.bitDepth),
        sampleRate: Value(metadata.sampleRate),
        channels: Value(metadata.channels),
        durationSeconds: Value(metadata.durationSeconds),
        fileSize: fileSize,
        year: Value(year),
        trackNumber: Value(trackNumber),
        discNumber: Value(discNumber),
        genre: Value(genre),
        bpm: Value(bpm),
        key: Value(key),
        isrc: Value(isrc),
        copyright: Value(copyright),
        replayGain: Value(replayGain),
        peak: Value(peak),
        version: Value(version),
        audioQualityLabel: const Value('verified'),
        vibrantColor: Value(requested.vibrantColor),
      ),
    );
    return TrackSummary(
      id: requested.id,
      provider: requested.provider,
      providerTrackId: requested.providerTrackId,
      title: title,
      artist: artist,
      album: album,
      artworkUrl: artworkPath,
      durationSeconds: metadata.durationSeconds,
      explicit: requested.explicit,
      quality: quality,
      localPath: finalFile.path,
      fileSize: fileSize,
      year: year,
      trackNumber: trackNumber,
      discNumber: discNumber,
      genre: genre,
      bpm: bpm,
      key: key,
      isrc: isrc,
      copyright: copyright,
      replayGain: replayGain,
      peak: peak,
      version: version,
      vibrantColor: requested.vibrantColor,
    );
  }

  static String safePathSegment(String value) =>
      value.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
}

final localImportServiceProvider = Provider(LocalImportService.new);
