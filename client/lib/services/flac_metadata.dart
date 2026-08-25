import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class FlacMetadata {
  const FlacMetadata({
    this.title,
    this.artist,
    this.album,
    required this.sampleRate,
    required this.bitDepth,
    required this.channels,
    required this.durationSeconds,
  });

  final String? title;
  final String? artist;
  final String? album;
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
      var isLast = false;

      while (!isLast) {
        final header = await source.read(4);
        if (header.length != 4) {
          throw const FormatException('The FLAC metadata is incomplete.');
        }
        isLast = header[0] & 0x80 != 0;
        final type = header[0] & 0x7f;
        final length = (header[1] << 16) | (header[2] << 8) | header[3];
        if (length > 16 * 1024 * 1024) {
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
        }
      }

      if (sampleRate == null ||
          sampleRate <= 0 ||
          bitDepth == null ||
          channels == null) {
        throw const FormatException('The FLAC stream information is missing.');
      }
      return FlacMetadata(
        title: comments['TITLE'],
        artist: comments['ARTIST'] ?? comments['ALBUMARTIST'],
        album: comments['ALBUM'],
        sampleRate: sampleRate,
        bitDepth: bitDepth,
        channels: channels,
        durationSeconds: durationSeconds ?? 0,
      );
    } finally {
      await source.close();
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
