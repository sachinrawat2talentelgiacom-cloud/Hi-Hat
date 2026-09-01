import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hi_hat/core/theme.dart';
import 'package:hi_hat/services/file_integrity.dart';
import 'package:hi_hat/widgets/app_widgets.dart';

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

  testWidgets('album hero remains usable on a 320dp phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: HiHatTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: HeroBanner(
                title: 'A very long album title for a narrow display',
                subtitle: 'By An Artist With A Long Name',
                songCountText: '14 songs',
                durationText: '1 hr 12 min',
                qualityBadge: 'FLAC Lossless',
                onPlayAll: () {},
                onShuffle: () {},
                onMore: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Play all'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    expect(find.text('FLAC Lossless'), findsOneWidget);
    expect(tester.getRect(find.text('Play all')).left, greaterThanOrEqualTo(0));
    expect(tester.getRect(find.text('Play all')).right, lessThanOrEqualTo(320));
  });
}
