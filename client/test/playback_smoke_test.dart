@Tags(['playback-smoke'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  test('media_kit loads, plays, pauses, and seeks in a local FLAC', () async {
    final path = Platform.environment['HIHAT_PLAYBACK_SMOKE_FILE'];
    expect(path, isNotNull, reason: 'HIHAT_PLAYBACK_SMOKE_FILE is required.');
    expect(File(path!).existsSync(), isTrue);

    final player = Player();
    try {
      await player.open(Media(path), play: false);
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
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('media_kit naturally plays a local FLAC through completion', () async {
    if (Platform.environment['HIHAT_FULL_PLAYBACK_SMOKE'] != '1') return;
    final path = Platform.environment['HIHAT_PLAYBACK_SMOKE_FILE'];
    expect(path, isNotNull, reason: 'HIHAT_PLAYBACK_SMOKE_FILE is required.');

    final player = Player();
    try {
      await player.open(Media(path!), play: false);
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
  }, timeout: const Timeout(Duration(minutes: 10)));
}
