import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/services/flac_metadata.dart';

void main() {
  test('reads FLAC stream info and Vorbis comments', () async {
    final directory = await Directory.systemTemp.createTemp(
      'hi-hat-flac-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/track.flac');
    await file.writeAsBytes(_fixture());

    final metadata = await FlacMetadataReader.read(file);

    expect(metadata.title, 'Daylight');
    expect(metadata.artist, 'Aster');
    expect(metadata.album, 'Morning');
    expect(metadata.sampleRate, 96000);
    expect(metadata.bitDepth, 24);
    expect(metadata.channels, 2);
    expect(metadata.durationSeconds, 10);
  });

  test('rejects a file without a FLAC marker', () async {
    final directory = await Directory.systemTemp.createTemp(
      'hi-hat-invalid-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/fake.flac');
    await file.writeAsBytes('not flac'.codeUnits);

    expect(() => FlacMetadataReader.read(file), throwsFormatException);
  });
}

List<int> _fixture() {
  final streamInfo = Uint8List(34);
  const sampleRate = 96000;
  const channelsMinusOne = 1;
  const bitsMinusOne = 23;
  streamInfo[10] = sampleRate >> 12;
  streamInfo[11] = (sampleRate >> 4) & 0xff;
  streamInfo[12] =
      ((sampleRate & 0x0f) << 4) |
      (channelsMinusOne << 1) |
      (bitsMinusOne >> 4);
  streamInfo[13] = (bitsMinusOne & 0x0f) << 4;
  const totalSamples = sampleRate * 10;
  streamInfo[14] = (totalSamples >> 24) & 0xff;
  streamInfo[15] = (totalSamples >> 16) & 0xff;
  streamInfo[16] = (totalSamples >> 8) & 0xff;
  streamInfo[17] = totalSamples & 0xff;

  final comments = ['TITLE=Daylight', 'ARTIST=Aster', 'ALBUM=Morning'];
  final commentBytes = BytesBuilder();
  commentBytes.add(_littleEndian(0));
  commentBytes.add(_littleEndian(comments.length));
  for (final comment in comments) {
    final bytes = comment.codeUnits;
    commentBytes.add(_littleEndian(bytes.length));
    commentBytes.add(bytes);
  }
  final vorbis = commentBytes.takeBytes();

  return [
    ...'fLaC'.codeUnits,
    0,
    0,
    0,
    streamInfo.length,
    ...streamInfo,
    0x84,
    (vorbis.length >> 16) & 0xff,
    (vorbis.length >> 8) & 0xff,
    vorbis.length & 0xff,
    ...vorbis,
  ];
}

List<int> _littleEndian(int value) => [
  value & 0xff,
  (value >> 8) & 0xff,
  (value >> 16) & 0xff,
  (value >> 24) & 0xff,
];
