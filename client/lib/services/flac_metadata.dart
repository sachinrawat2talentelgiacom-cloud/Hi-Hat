import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class FlacPicture {
  const FlacPicture({
    required this.pictureType,
    required this.mimeType,
    required this.description,
    required this.width,
    required this.height,
    required this.colorDepth,
    required this.data,
  });

  final int pictureType;
  final String mimeType;
  final String description;
  final int width;
  final int height;
  final int colorDepth;
  final Uint8List data;
}

class FlacMetadata {
  const FlacMetadata({
    this.title,
    this.artist,
    this.album,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.genre,
    this.bpm,
    this.key,
    this.isrc,
    this.copyright,
    this.replayGain,
    this.peak,
    this.version,
    this.picture,
    required this.sampleRate,
    required this.bitDepth,
    required this.channels,
    required this.durationSeconds,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? year;
  final int? trackNumber;
  final int? discNumber;
  final String? genre;
  final int? bpm;
  final String? key;
  final String? isrc;
  final String? copyright;
  final double? replayGain;
  final double? peak;
  final String? version;
  final FlacPicture? picture;
  final int sampleRate;
  final int bitDepth;
  final int channels;
  final double durationSeconds;
}

class FlacMetadataReader {
  static Future<FlacMetadata> read(File file) async {
    final source = await file.open();
    try {
      final marker = await source.read(4);
      if (marker.length != 4 || ascii.decode(marker) != 'fLaC') {
        throw const FormatException('The selected file is not a valid FLAC.');
      }

      int? sampleRate;
      int? bitDepth;
      int? channels;
      double? durationSeconds;
      final comments = <String, String>{};
      FlacPicture? frontCover;
      FlacPicture? fallbackPicture;
      var isLast = false;

      while (!isLast) {
        final header = await source.read(4);
        if (header.length != 4) {
          throw const FormatException('The FLAC metadata is incomplete.');
        }
        isLast = header[0] & 0x80 != 0;
        final type = header[0] & 0x7f;
        final length = (header[1] << 16) | (header[2] << 8) | header[3];
        if (length > 32 * 1024 * 1024) {
          throw const FormatException('The FLAC metadata block is too large.');
        }
        final block = await source.read(length);
        if (block.length != length) {
          throw const FormatException('The FLAC metadata is incomplete.');
        }

        if (type == 0) {
          if (block.length < 34) {
            throw const FormatException(
              'The FLAC stream information is invalid.',
            );
          }
          sampleRate = (block[10] << 12) | (block[11] << 4) | (block[12] >> 4);
          channels = ((block[12] & 0x0e) >> 1) + 1;
          bitDepth = (((block[12] & 0x01) << 4) | (block[13] >> 4)) + 1;
          final totalSamples =
              ((block[13] & 0x0f) * 0x100000000) +
              (block[14] << 24) +
              (block[15] << 16) +
              (block[16] << 8) +
              block[17];
          durationSeconds = totalSamples / sampleRate;
        } else if (type == 4) {
          comments.addAll(_vorbisComments(block));
        } else if (type == 6) {
          final pic = _parsePicture(block);
          if (pic != null) {
            if (pic.pictureType == 3) {
              frontCover = pic;
            } else {
              fallbackPicture ??= pic;
            }
          }
        }
      }

      if (sampleRate == null ||
          sampleRate <= 0 ||
          bitDepth == null ||
          channels == null) {
        throw const FormatException('The FLAC stream information is missing.');
      }

      final dateStr = comments['DATE'] ??
          comments['YEAR'] ??
          comments['ORIGINALDATE'] ??
          comments['ORIGINALYEAR'];
      String? year;
      if (dateStr != null) {
        final match = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(dateStr);
        year = match != null ? match.group(1) : dateStr;
      }

      final trackNumStr = comments['TRACKNUMBER'];
      int? trackNumber;
      if (trackNumStr != null) {
        trackNumber = int.tryParse(trackNumStr.split('/').first.trim());
      }

      final discNumStr = comments['DISCNUMBER'];
      int? discNumber;
      if (discNumStr != null) {
        discNumber = int.tryParse(discNumStr.split('/').first.trim());
      }

      final bpmStr = comments['BPM'] ?? comments['TEMPO'];
      int? bpm;
      if (bpmStr != null) {
        bpm = (double.tryParse(bpmStr.trim()))?.round();
      }

      final gainStr = comments['REPLAYGAIN_TRACK_GAIN'];
      double? replayGain;
      if (gainStr != null) {
        final match = RegExp(r'[-+]?\d+(?:\.\d+)?').firstMatch(gainStr);
        if (match != null) replayGain = double.tryParse(match.group(0)!);
      }

      final peakStr = comments['REPLAYGAIN_TRACK_PEAK'];
      double? peak;
      if (peakStr != null) {
        final match = RegExp(r'[-+]?\d+(?:\.\d+)?').firstMatch(peakStr);
        if (match != null) peak = double.tryParse(match.group(0)!);
      }

      return FlacMetadata(
        title: comments['TITLE'],
        artist: comments['ARTIST'] ??
            comments['ALBUMARTIST'] ??
            comments['PERFORMER'],
        album: comments['ALBUM'],
        year: year,
        trackNumber: trackNumber,
        discNumber: discNumber,
        genre: comments['GENRE'],
        bpm: bpm,
        key: comments['KEY'] ?? comments['INITIALKEY'],
        isrc: comments['ISRC'],
        copyright: comments['COPYRIGHT'] ??
            comments['ORGANIZATION'] ??
            comments['LABEL'] ??
            comments['PUBLISHER'],
        replayGain: replayGain,
        peak: peak,
        version: comments['VERSION'] ?? comments['SUBTITLE'],
        picture: frontCover ?? fallbackPicture,
        sampleRate: sampleRate,
        bitDepth: bitDepth,
        channels: channels,
        durationSeconds: durationSeconds ?? 0,
      );
    } finally {
      await source.close();
    }
  }

  static FlacPicture? _parsePicture(Uint8List block) {
    try {
      if (block.length < 32) return null;
      var offset = 0;
      int readUint32() {
        if (offset + 4 > block.length) return 0;
        final val = ByteData.sublistView(
          block,
          offset,
          offset + 4,
        ).getUint32(0, Endian.big);
        offset += 4;
        return val;
      }

      final pictureType = readUint32();
      final mimeLength = readUint32();
      if (offset + mimeLength > block.length) return null;
      final mimeType = ascii.decode(block.sublist(offset, offset + mimeLength));
      offset += mimeLength;

      final descLength = readUint32();
      if (offset + descLength > block.length) return null;
      final description = utf8.decode(
        block.sublist(offset, offset + descLength),
        allowMalformed: true,
      );
      offset += descLength;

      if (offset + 16 > block.length) return null;
      final width = readUint32();
      final height = readUint32();
      final colorDepth = readUint32();
      readUint32(); // colors used

      final dataLength = readUint32();
      if (offset + dataLength > block.length) return null;
      final data = Uint8List.fromList(block.sublist(offset, offset + dataLength));

      return FlacPicture(
        pictureType: pictureType,
        mimeType: mimeType,
        description: description,
        width: width,
        height: height,
        colorDepth: colorDepth,
        data: data,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _vorbisComments(Uint8List block) {
    final values = <String, String>{};
    var offset = 0;
    int readUint32() {
      if (offset + 4 > block.length) {
        throw const FormatException('Invalid FLAC comments.');
      }
      final value = ByteData.sublistView(
        block,
        offset,
        offset + 4,
      ).getUint32(0, Endian.little);
      offset += 4;
      return value;
    }

    final vendorLength = readUint32();
    if (offset + vendorLength > block.length) {
      throw const FormatException('Invalid FLAC comments.');
    }
    offset += vendorLength;
    final count = readUint32();
    if (count > 10000) throw const FormatException('Invalid FLAC comments.');
    for (var index = 0; index < count; index++) {
      final length = readUint32();
      if (offset + length > block.length) {
        throw const FormatException('Invalid FLAC comments.');
      }
      final comment = utf8.decode(
        block.sublist(offset, offset + length),
        allowMalformed: true,
      );
      offset += length;
      final separator = comment.indexOf('=');
      if (separator > 0) {
        final key = comment.substring(0, separator).toUpperCase();
        final value = comment.substring(separator + 1).trim();
        if (value.isNotEmpty) values.putIfAbsent(key, () => value);
      }
    }
    return values;
  }
}
