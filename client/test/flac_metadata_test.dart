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
    expect(metadata.year, '2023');
    expect(metadata.trackNumber, 3);
    expect(metadata.discNumber, 1);
    expect(metadata.bpm, 120);
    expect(metadata.key, 'C Major');
    expect(metadata.isrc, 'USABC1234567');
    expect(metadata.replayGain, -4.5);
    expect(metadata.sampleRate, 96000);
    expect(metadata.bitDepth, 24);
    expect(metadata.channels, 2);
    expect(metadata.durationSeconds, 10);
    expect(metadata.picture, isNotNull);
    expect(metadata.picture!.pictureType, 3);
    expect(metadata.picture!.mimeType, 'image/jpeg');
    expect(metadata.picture!.data.length, 4);
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

  final comments = [
    'TITLE=Daylight',
    'ARTIST=Aster',
    'ALBUM=Morning',
    'DATE=2023-05-12',
    'TRACKNUMBER=3/10',
    'DISCNUMBER=1',
    'BPM=120',
    'KEY=C Major',
    'ISRC=USABC1234567',
    'REPLAYGAIN_TRACK_GAIN=-4.5 dB',
  ];
  final commentBytes = BytesBuilder();
  commentBytes.add(_littleEndian(0));
  commentBytes.add(_littleEndian(comments.length));
  for (final comment in comments) {
    final bytes = comment.codeUnits;
    commentBytes.add(_littleEndian(bytes.length));
    commentBytes.add(bytes);
  }
  final vorbis = commentBytes.takeBytes();

  // Picture block (type 6)
  final pictureBytes = BytesBuilder();
  pictureBytes.add(_bigEndian(3)); // Type 3 = Front Cover
  final mime = 'image/jpeg'.codeUnits;
  pictureBytes.add(_bigEndian(mime.length));
  pictureBytes.add(mime);
  pictureBytes.add(_bigEndian(0)); // Description length 0
  pictureBytes.add(_bigEndian(500)); // Width
  pictureBytes.add(_bigEndian(500)); // Height
  pictureBytes.add(_bigEndian(24)); // Color depth
  pictureBytes.add(_bigEndian(0)); // Colors used
  final fakeImgData = [0xFF, 0xD8, 0xFF, 0xE0];
  pictureBytes.add(_bigEndian(fakeImgData.length));
  pictureBytes.add(fakeImgData);
  final pictureBlock = pictureBytes.takeBytes();

  return [
    ...'fLaC'.codeUnits,
    0, // not last, type 0 = STREAMINFO
    0,
    0,
    streamInfo.length,
    ...streamInfo,
    4, // not last, type 4 = VORBIS_COMMENT
    (vorbis.length >> 16) & 0xff,
    (vorbis.length >> 8) & 0xff,
    vorbis.length & 0xff,
    ...vorbis,
    0x86, // isLast (0x80 | 6), type 6 = PICTURE
    (pictureBlock.length >> 16) & 0xff,
    (pictureBlock.length >> 8) & 0xff,
    pictureBlock.length & 0xff,
    ...pictureBlock,
  ];
}

List<int> _littleEndian(int value) => [
  value & 0xff,
  (value >> 8) & 0xff,
  (value >> 16) & 0xff,
  (value >> 24) & 0xff,
];

List<int> _bigEndian(int value) => [
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];
