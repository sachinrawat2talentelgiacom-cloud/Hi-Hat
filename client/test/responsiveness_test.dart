import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hi_hat/services/file_integrity.dart';

void main() {
  test('large-file hashing leaves the UI event loop responsive', () async {
    final directory = await Directory.systemTemp.createTemp('hi-hat-hash-');
    final file = File('${directory.path}${Platform.pathSeparator}audio.flac');
    await file.writeAsBytes(List<int>.filled(8 * 1024 * 1024, 7));
    var eventLoopAdvanced = false;
    Timer.run(() => eventLoopAdvanced = true);
    final digest = await sha256File(file);
    expect(eventLoopAdvanced, isTrue);
    expect(digest, hasLength(64));
    await directory.delete(recursive: true);
  });
}
