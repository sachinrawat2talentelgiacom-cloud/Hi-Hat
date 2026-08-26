import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../models/track.dart';

class PlaybackState {
  const PlaybackState({
    this.track,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.outputLabel = 'System mixed',
  });
  final TrackSummary? track;
  final bool playing;
  final Duration position;
  final Duration duration;
  final String outputLabel;

  PlaybackState copyWith({
    TrackSummary? track,
    bool? playing,
    Duration? position,
    Duration? duration,
    String? outputLabel,
  }) => PlaybackState(
    track: track ?? this.track,
    playing: playing ?? this.playing,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    outputLabel: outputLabel ?? this.outputLabel,
  );
}

class AudioEngine extends StateNotifier<PlaybackState> {
  AudioEngine() : super(const PlaybackState()) {
    _subscriptions = [
      _player.stream.playing.listen(
        (value) => state = state.copyWith(playing: value),
      ),
      _player.stream.position.listen(
        (value) => state = state.copyWith(position: value),
      ),
      _player.stream.duration.listen(
        (value) => state = state.copyWith(duration: value),
      ),
    ];
  }

  final Player _player = Player();
  late final List<StreamSubscription<dynamic>> _subscriptions;

  Future<void> playLocal(TrackSummary track) async {
    if (track.localPath == null) return;
    state = state.copyWith(track: track);
    await _player.open(Media(track.localPath!), play: true);
  }

  void showTrack(TrackSummary track) => state = state.copyWith(track: track);
  Future<void> toggle() => _player.playOrPause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> stop() => _player.stop();

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}

final audioEngineProvider = StateNotifierProvider<AudioEngine, PlaybackState>(
  (ref) => AudioEngine(),
);
