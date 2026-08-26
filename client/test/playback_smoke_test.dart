@Tags(['playback-smoke'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final smokeFile = Platform.environment['HIHAT_PLAYBACK_SMOKE_FILE'];

  void initializeMediaKit() {
    MediaKit.ensureInitialized();
  }

  test(
    'media_kit loads, plays, pauses, and seeks in a local FLAC',
    () async {
      initializeMediaKit();
      expect(File(smokeFile!).existsSync(), isTrue);

      final player = Player();
      try {
        await player.open(Media(smokeFile), play: false);
        final duration = await player.stream.duration
            .firstWhere((value) => value > Duration.zero)
            .timeout(const Duration(seconds: 10));
        expect(duration, greaterThan(Duration.zero));
        await player.play();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await player.pause();
        await player.seek(duration ~/ 2);
        await player.play();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await player.stop();
      } finally {
        await player.dispose();
      }
    },
    skip: smokeFile == null
        ? 'Set HIHAT_PLAYBACK_SMOKE_FILE to run native playback smoke tests.'
        : false,
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'media_kit naturally plays a local FLAC through completion',
    () async {
      initializeMediaKit();

      final player = Player();
      try {
        await player.open(Media(smokeFile!), play: false);
        final duration = await player.stream.duration
            .firstWhere((value) => value > Duration.zero)
            .timeout(const Duration(seconds: 10));
        var furthestPosition = Duration.zero;
        final positionSubscription = player.stream.position.listen((position) {
          if (position > furthestPosition) furthestPosition = position;
        });
        try {
          await player.play();
          await player.stream.completed
              .firstWhere((completed) => completed)
              .timeout(duration + const Duration(seconds: 30));
        } finally {
          await positionSubscription.cancel();
        }
        expect(furthestPosition, greaterThan(Duration.zero));
        expect(
          (duration - furthestPosition).abs(),
          lessThanOrEqualTo(const Duration(seconds: 3)),
        );
      } finally {
        await player.dispose();
      }
    },
    skip:
        smokeFile == null ||
            Platform.environment['HIHAT_FULL_PLAYBACK_SMOKE'] != '1'
        ? 'Set HIHAT_PLAYBACK_SMOKE_FILE and HIHAT_FULL_PLAYBACK_SMOKE=1 '
              'to run the full playback smoke test.'
        : false,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
