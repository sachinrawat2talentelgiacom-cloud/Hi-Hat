import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';
import 'discovery_service.dart';
import 'provider_search_service.dart';

enum PlaybackRepeatMode { off, queue, one }

class PlaybackState {
  const PlaybackState({
    this.track,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.outputLabel = 'System mixed',
    this.volume = .8,
    this.previousVolume = .8,
    this.queue = const [],
    this.currentIndex = -1,
    this.shuffle = false,
    this.repeatMode = PlaybackRepeatMode.off,
    this.relatedAutoplay = true,
    this.history = const [],
    this.error,
  });
  final TrackSummary? track;
  final bool playing;
  final Duration position, duration;
  final String outputLabel;
  final double volume, previousVolume;
  final List<TrackSummary> queue;
  final int currentIndex;
  final bool shuffle, relatedAutoplay;
  final PlaybackRepeatMode repeatMode;
  final List<int> history;
  final String? error;
  bool get muted => volume == 0;

  PlaybackState copyWith({
    TrackSummary? track,
    bool? playing,
    Duration? position,
    Duration? duration,
    String? outputLabel,
    double? volume,
    double? previousVolume,
    List<TrackSummary>? queue,
    int? currentIndex,
    bool? shuffle,
    PlaybackRepeatMode? repeatMode,
    bool? relatedAutoplay,
    List<int>? history,
    String? error,
    bool clearError = false,
  }) => PlaybackState(
    track: track ?? this.track,
    playing: playing ?? this.playing,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    outputLabel: outputLabel ?? this.outputLabel,
    volume: volume ?? this.volume,
    previousVolume: previousVolume ?? this.previousVolume,
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
    shuffle: shuffle ?? this.shuffle,
    repeatMode: repeatMode ?? this.repeatMode,
    relatedAutoplay: relatedAutoplay ?? this.relatedAutoplay,
    history: history ?? this.history,
    error: clearError ? null : error ?? this.error,
  );
}

class AudioEngine extends StateNotifier<PlaybackState> {
  AudioEngine(this._search, {AudioPlayerAdapter? player, Random? random})
    : _player = player ?? MediaKitAudioPlayer(),
      _random = random ?? Random(),
      super(const PlaybackState()) {
    _subscriptions = [
      _player.playingStream.listen((v) => state = state.copyWith(playing: v)),
      _player.positionStream.listen((v) => state = state.copyWith(position: v)),
      _player.durationStream.listen((v) => state = state.copyWith(duration: v)),
      _player.completedStream.listen((v) {
        if (v) unawaited(next(automatic: true));
      }),
      _player.errorStream.listen((_) {
        state = state.copyWith(
          error: 'This track could not be played. Skipping it.',
        );
        unawaited(next(automatic: true));
      }),
    ];
    unawaited(_restore());
  }

  static const _key = 'playback_state_v2';
  static const maxQueue = 200, maxHistory = 100, relatedThreshold = 3;
  final AudioPlayerAdapter _player;
  final ProviderSearchService _search;
  final Random _random;
  late final List<StreamSubscription<dynamic>> _subscriptions;
  bool _extending = false;
  int _relatedFailures = 0;
  DateTime? _relatedRetryAfter;

  Future<void> _restore() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final queue = (json['queue'] as List? ?? const [])
          .whereType<Map>()
          .map((v) => TrackSummary.fromJson(Map<String, dynamic>.from(v)))
          .take(maxQueue)
          .toList();
      final index = ((json['current_index'] as num?)?.toInt() ?? -1).clamp(
        -1,
        queue.length - 1,
      );
      final volume = ((json['volume'] as num?)?.toDouble() ?? .8).clamp(
        0.0,
        1.0,
      );
      state = state.copyWith(
        queue: queue,
        currentIndex: index,
        track: index >= 0 ? queue[index] : null,
        volume: volume,
        previousVolume: ((json['previous_volume'] as num?)?.toDouble() ?? .8)
            .clamp(.01, 1.0),
        shuffle: json['shuffle'] == true,
        repeatMode:
            PlaybackRepeatMode.values
                .where((m) => m.name == json['repeat'])
                .firstOrNull ??
            PlaybackRepeatMode.off,
        relatedAutoplay: ((json['schema'] as num?)?.toInt() ?? 0) < 3
            ? true
            : json['related_autoplay'] as bool? ?? true,
      );
      await _player.setVolume(volume * 100);
    } catch (_) {
      state = state.copyWith(
        error: 'The previous playback session could not be restored.',
      );
    }
  }

  Future<void> _persist() async {
    final start = max(0, state.queue.length - maxQueue);
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode({
        'schema': 3,
        'volume': state.volume,
        'previous_volume': state.previousVolume,
        'shuffle': state.shuffle,
        'repeat': state.repeatMode.name,
        'related_autoplay': state.relatedAutoplay,
        'current_index': state.currentIndex < start
            ? -1
            : state.currentIndex - start,
        'queue': state.queue.skip(start).map((t) => t.toJson()).toList(),
      }),
    );
  }

  Future<void> playLocal(TrackSummary track) async {
    if (state.relatedAutoplay) {
      state = state.copyWith(queue: [track], currentIndex: -1, history: []);
      await playAt(0);
      return;
    }
    var index = state.queue.indexWhere((item) => identical(item, track));
    if (index < 0) {
      final queue = [...state.queue, track];
      index = queue.length - 1;
      state = state.copyWith(queue: queue);
    }
    await playAt(index);
  }

  Future<void> playNow(TrackSummary track) async {
    final index = state.currentIndex < 0 ? 0 : state.currentIndex + 1;
    state = state.copyWith(queue: [...state.queue]..insert(index, track));
    await playAt(index);
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    final track = state.queue[index];
    if (track.localPath == null || track.localPath!.isEmpty) {
      state = state.copyWith(
        error: '${track.displayTitle} is not downloaded; skipping it.',
      );
      await next(automatic: true, fromIndex: index);
      return;
    }
    final history = state.currentIndex >= 0 && state.currentIndex != index
        ? _takeLast([...state.history, state.currentIndex], maxHistory)
        : state.history;
    state = state.copyWith(
      track: track,
      currentIndex: index,
      position: Duration.zero,
      history: history,
      clearError: true,
    );
    await _persist();
    try {
      await _player.open(track.localPath!);
      unawaited(_extendRelated());
    } catch (_) {
      state = state.copyWith(
        error: '${track.displayTitle} is unavailable; skipping it.',
      );
      await next(automatic: true, fromIndex: index);
    }
  }

  Future<void> addToQueue(TrackSummary track) async {
    state = state.copyWith(queue: [...state.queue, track]);
    await _persist();
  }

  Future<void> addAllToQueue(Iterable<TrackSummary> tracks) async {
    state = state.copyWith(queue: [...state.queue, ...tracks]);
    await _persist();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final queue = [...state.queue];
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    var current = state.currentIndex;
    if (current == oldIndex) {
      current = newIndex;
    } else if (oldIndex < current && newIndex >= current) {
      current--;
    } else if (oldIndex > current && newIndex <= current) {
      current++;
    }
    state = state.copyWith(queue: queue, currentIndex: current);
    await _persist();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    final queue = [...state.queue]..removeAt(index);
    var current = state.currentIndex;
    if (index < current) current--;
    if (index == current) {
      await _player.stop();
      current = -1;
    }
    state = PlaybackState(
      track: current >= 0 ? queue[current] : null,
      queue: queue,
      currentIndex: current,
      volume: state.volume,
      previousVolume: state.previousVolume,
      shuffle: state.shuffle,
      repeatMode: state.repeatMode,
      relatedAutoplay: state.relatedAutoplay,
      history: state.history,
    );
    await _persist();
  }

  Future<void> clearQueue() async {
    await _player.stop();
    state = PlaybackState(
      volume: state.volume,
      previousVolume: state.previousVolume,
      shuffle: state.shuffle,
      repeatMode: state.repeatMode,
      relatedAutoplay: state.relatedAutoplay,
    );
    await _persist();
  }

  Future<void> next({bool automatic = false, int? fromIndex}) async {
    if (state.queue.isEmpty) return;
    if (automatic &&
        state.repeatMode == PlaybackRepeatMode.one &&
        state.currentIndex >= 0) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    final origin = fromIndex ?? state.currentIndex;
    int index;
    if (state.shuffle && state.queue.length > 1) {
      final candidates = List.generate(state.queue.length, (i) => i)
        ..remove(origin);
      index = candidates[_random.nextInt(candidates.length)];
    } else {
      index = origin + 1;
      if (index >= state.queue.length) {
        if (state.repeatMode == PlaybackRepeatMode.queue) {
          index = 0;
        } else {
          await _player.stop();
          state = state.copyWith(playing: false);
          return;
        }
      }
    }
    await playAt(index);
  }

  Future<void> previous() async {
    if (state.position > const Duration(seconds: 5)) {
      await seek(Duration.zero);
      return;
    }
    if (state.history.isNotEmpty) {
      final history = [...state.history];
      final index = history.removeLast();
      state = state.copyWith(history: history);
      await playAt(index);
    } else if (state.currentIndex > 0) {
      await playAt(state.currentIndex - 1);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> setVolume(double value) async {
    final v = value.clamp(0.0, 1.0);
    state = state.copyWith(
      volume: v,
      previousVolume: v > 0 ? v : state.previousVolume,
    );
    await _player.setVolume(v * 100);
    await _persist();
  }

  Future<void> toggleMute() =>
      setVolume(state.muted ? state.previousVolume : 0);
  Future<void> toggleShuffle() async {
    state = state.copyWith(shuffle: !state.shuffle);
    await _persist();
  }

  Future<void> cycleRepeat() async {
    state = state.copyWith(
      repeatMode:
          PlaybackRepeatMode.values[(state.repeatMode.index + 1) %
              PlaybackRepeatMode.values.length],
    );
    await _persist();
  }

  Future<void> setRelatedAutoplay(bool v) async {
    state = state.copyWith(relatedAutoplay: v);
    await _persist();
    if (v) unawaited(_extendRelated());
  }

  Future<void> refreshRelatedQueue() => _extendRelated(forceRebuild: true);

  Future<void> _extendRelated({bool forceRebuild = false}) async {
    if (!state.relatedAutoplay ||
        _extending ||
        (!forceRebuild &&
            (_relatedRetryAfter?.isAfter(DateTime.now()) ?? false)) ||
        state.track == null ||
        (!forceRebuild &&
            state.queue.length - state.currentIndex > relatedThreshold)) {
      return;
    }
    _extending = true;
    try {
      final current = state.track!;
      if (forceRebuild) {
        state = state.copyWith(queue: [current], currentIndex: 0, history: []);
      }
      final results = await _findRelated(current);
      if (state.track?.providerTrackId != current.providerTrackId) return;
      final ids = state.queue.map((t) => t.providerTrackId).toSet();
      final candidates = results
          .where(
            (track) =>
                !ids.contains(track.providerTrackId) &&
                track.providerTrackId != current.providerTrackId,
          )
          .toList(growable: false);
      if (candidates.isNotEmpty) {
        final all = [...state.queue, ...candidates.take(8)];
        final removed = max(0, all.length - maxQueue);
        state = state.copyWith(
          queue: removed == 0 ? all : all.sublist(removed),
          currentIndex: max(-1, state.currentIndex - removed),
        );
        await _persist();
        _relatedFailures = 0;
        _relatedRetryAfter = null;
      }
    } catch (_) {
      _relatedFailures = min(_relatedFailures + 1, 6);
      _relatedRetryAfter = DateTime.now().add(
        Duration(seconds: 1 << _relatedFailures),
      );
    } finally {
      _extending = false;
    }
  }

  Future<List<TrackSummary>> _findRelated(TrackSummary current) async {
    final artistResults = await _search.search(current.artist, limit: 50);
    final sameArtist = artistResults
        .where(
          (track) =>
              DiscoveryService.artistMatches(track.artist, current.artist),
        )
        .toList(growable: false);
    final genres = <String>{
      ..._genreTokens(current.genre),
      ...?DiscoveryService.artistGenreSeeds[_normalize(current.artist)],
      for (final track in sameArtist) ..._genreTokens(track.genre),
    };
    final relatedArtists = <String>{};
    for (final track in sameArtist) {
      for (final artist in _creditedArtists(track.artist)) {
        if (!DiscoveryService.artistMatches(artist, current.artist)) {
          relatedArtists.add(artist);
        }
      }
    }

    final scored = <String, ({TrackSummary track, int score})>{};
    void consider(TrackSummary track, int score) {
      final identity = _trackIdentity(track);
      if (identity == _trackIdentity(current) || score <= 0) return;
      final existing = scored[identity];
      if (existing == null || score > existing.score) {
        scored[identity] = (track: track, score: score);
      }
    }

    for (final track in sameArtist) {
      final sameAlbum =
          _normalize(track.album ?? '').isNotEmpty &&
          _normalize(track.album ?? '') == _normalize(current.album ?? '');
      consider(track, 120 + (sameAlbum ? 20 : 0));
    }

    for (final artist in relatedArtists.take(2)) {
      final results = await _safeRelatedSearch(artist);
      for (final track in results.where(
        (track) => DiscoveryService.artistMatches(track.artist, artist),
      )) {
        consider(track, 80);
      }
    }

    for (final genre in genres.take(3)) {
      final results = await _safeRelatedSearch(genre);
      for (final track in results) {
        if (_sharesGenre(_genreTokens(track.genre), genres)) {
          consider(track, 60);
        }
      }
    }

    final ranked = scored.values.toList()
      ..sort((a, b) {
        final scoreOrder = b.score.compareTo(a.score);
        if (scoreOrder != 0) return scoreOrder;
        return a.track.displayTitle.compareTo(b.track.displayTitle);
      });
    return ranked.map((entry) => entry.track).take(24).toList(growable: false);
  }

  Future<List<TrackSummary>> _safeRelatedSearch(String query) async {
    try {
      return await _search.search(query, limit: 40);
    } catch (_) {
      return const [];
    }
  }

  static Set<String> _genreTokens(String? value) => (value ?? '')
      .split(RegExp(r'[,;/]'))
      .map(_normalize)
      .where((genre) => genre.isNotEmpty)
      .toSet();

  static bool _sharesGenre(Set<String> candidate, Set<String> seeds) =>
      candidate.any(
        (genre) => seeds.any(
          (seed) =>
              genre == seed || genre.contains(seed) || seed.contains(genre),
        ),
      );

  static List<String> _creditedArtists(String value) => value
      .split(RegExp(r'\s+(?:feat\.?|featuring|with|x)\s+|\s*[,;&]\s*'))
      .map((artist) => artist.trim())
      .where((artist) => artist.isNotEmpty)
      .toList(growable: false);

  static String _trackIdentity(TrackSummary track) =>
      '${_normalize(track.title)}|${_normalize(_creditedArtists(track.artist).firstOrNull ?? track.artist)}';

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  void showTrack(TrackSummary track) => state = state.copyWith(track: track);
  Future<void> toggle() => _player.playOrPause();
  Future<void> seek(Duration value) => _player.seek(value);
  Future<void> seekRelative(Duration delta) async {
    if (state.duration <= Duration.zero) return;
    final targetMs = (state.position + delta).inMilliseconds.clamp(
      0,
      state.duration.inMilliseconds,
    );
    await seek(Duration(milliseconds: targetMs));
  }

  Future<void> stop() => _player.stop();
  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}

List<T> _takeLast<T>(List<T> values, int count) =>
    values.length <= count ? values : values.sublist(values.length - count);

final audioEngineProvider = StateNotifierProvider<AudioEngine, PlaybackState>(
  (ref) => AudioEngine(ref.read(providerSearchServiceProvider)),
);

abstract class AudioPlayerAdapter {
  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<bool> get completedStream;
  Stream<String> get errorStream;
  Future<void> open(String path);
  Future<void> play();
  Future<void> playOrPause();
  Future<void> seek(Duration value);
  Future<void> stop();
  Future<void> setVolume(double value);
  Future<void> dispose();
}

class MediaKitAudioPlayer implements AudioPlayerAdapter {
  MediaKitAudioPlayer() : _player = Player();
  final Player _player;
  @override
  Stream<bool> get playingStream => _player.stream.playing;
  @override
  Stream<Duration> get positionStream => _player.stream.position;
  @override
  Stream<Duration> get durationStream => _player.stream.duration;
  @override
  Stream<bool> get completedStream => _player.stream.completed;
  @override
  Stream<String> get errorStream => _player.stream.error;
  @override
  Future<void> open(String path) => _player.open(Media(path), play: true);
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> playOrPause() => _player.playOrPause();
  @override
  Future<void> seek(Duration value) => _player.seek(value);
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> setVolume(double value) => _player.setVolume(value);
  @override
  Future<void> dispose() => _player.dispose();
}
