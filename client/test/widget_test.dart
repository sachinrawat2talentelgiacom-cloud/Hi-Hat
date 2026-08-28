import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hi_hat/core/theme.dart';
import 'package:hi_hat/features/player/player_panel.dart';
import 'package:hi_hat/features/player/full_player_screen.dart';
import 'package:hi_hat/features/search/search_screen.dart';
import 'package:hi_hat/models/track.dart';
import 'package:hi_hat/services/audio_engine.dart';
import 'package:hi_hat/widgets/track_artwork.dart';

class TestAudioEngine extends StateNotifier<PlaybackState>
    implements AudioEngine {
  TestAudioEngine([PlaybackState? initial])
    : super(initial ?? const PlaybackState());

  @override
  void showTrack(TrackSummary track) => state = state.copyWith(track: track);

  @override
  Future<void> playLocal(TrackSummary track) async {
    state = state.copyWith(track: track, playing: true);
  }

  @override
  Future<void> toggle() async {
    state = state.copyWith(playing: !state.playing);
  }

  @override
  Future<void> seek(Duration position) async {
    state = state.copyWith(position: position);
  }

  @override
  Future<void> stop() async {
    state = state.copyWith(playing: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'compact player opens full-screen player without changing playback',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const track = TrackSummary(
        id: 'local:nav',
        provider: 'local',
        providerTrackId: 'nav',
        title: 'Navigation Song',
        artist: 'Artist',
        localPath: 'song.flac',
      );
      final engine = TestAudioEngine(
        const PlaybackState(
          track: track,
          playing: true,
          queue: [track],
          currentIndex: 0,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [audioEngineProvider.overrideWith((ref) => engine)],
          child: MaterialApp(
            theme: HiHatTheme.dark,
            home: const Scaffold(body: MiniPlayer()),
          ),
        ),
      );
      await tester.tap(find.text('Navigation Song'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(FullPlayerScreen), findsOneWidget);
      expect(find.text('Now playing'), findsOneWidget);
      expect(engine.state.playing, isTrue);
    },
  );

  testWidgets('search surface exposes the primary task', (tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: HiHatTheme.dark,
        home: const ProviderScope(child: Scaffold(body: SearchScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('Search'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search songs, artists, and albums'), findsOneWidget);
    expect(find.text('LOSSLESS FLAC'), findsOneWidget);

    final field = tester.getRect(find.byType(TextField));
    final icon = tester.getRect(find.byIcon(Icons.search_rounded));
    expect((field.center.dy - icon.center.dy).abs(), lessThan(1));
  });

  testWidgets('desktop compact player exposes a substantial volume fader', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const track = TrackSummary(
      id: 'local:fader',
      provider: 'local',
      providerTrackId: 'fader',
      title: 'Signal Check',
      artist: 'Hi Hat',
      localPath: 'signal.flac',
    );
    final engine = TestAudioEngine(
      const PlaybackState(track: track, volume: .72),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioEngineProvider.overrideWith((ref) => engine)],
        child: MaterialApp(
          theme: HiHatTheme.dark,
          home: const Scaffold(body: MiniPlayer()),
        ),
      ),
    );

    expect(find.byType(Slider), findsNWidgets(2));
    final slider = tester.getRect(find.byType(Slider).first);
    expect(slider.width, greaterThanOrEqualTo(100));
  });

  testWidgets(
    'TrackResultTile displays artwork, explicit badge, album, duration and key',
    (tester) async {
      const track = TrackSummary(
        id: 'monochrome:1550546',
        provider: 'monochrome',
        providerTrackId: '1550546',
        title: 'One More Time',
        artist: 'Daft Punk',
        album: 'Discovery',
        year: '2001',
        durationSeconds: 320,
        explicit: true,
        bpm: 123,
        key: 'G Major',
        artworkUrl: 'https://resources.tidal.com/images/7d3b9810/5634/400c/ad89/50609e0ce800/640x640.jpg',
        quality: AudioQuality(
          codec: 'FLAC',
          lossless: true,
          label: 'HI_RES_LOSSLESS',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: HiHatTheme.dark,
          home: ProviderScope(
            child: Scaffold(
              body: TrackResultTile(track: track, onPlay: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('One More Time'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('Discovery (2001)'), findsOneWidget);
      expect(find.text('5:20'), findsOneWidget);
      expect(find.text('123 BPM · G Major'), findsOneWidget);
      expect(find.text('E'), findsOneWidget); // Explicit badge
      expect(find.byType(TrackArtwork), findsOneWidget);
    },
  );

  testWidgets(
    'PlayerPanel displays large artwork, acoustic readings and catalog metadata',
    (tester) async {
      const track = TrackSummary(
        id: 'local:abc',
        provider: 'local',
        providerTrackId: 'abc',
        title: 'Harder Better Faster Stronger',
        artist: 'Daft Punk',
        album: 'Discovery',
        year: '2001',
        durationSeconds: 224,
        bpm: 123,
        key: 'F# Minor',
        trackNumber: 4,
        isrc: 'GBDUW0000055',
        copyright: '℗ 2001 Daft Life Limited',
        replayGain: -6.8,
        peak: 0.98,
        localPath: r'C:\Music\Daft Punk\Discovery\04. Harder Better Faster Stronger.flac',
        fileSize: 34500000,
        quality: AudioQuality(
          codec: 'FLAC',
          lossless: true,
          bitDepth: 24,
          sampleRate: 96000,
          channels: 2,
          bitrate: 2450000,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: HiHatTheme.dark,
          home: ProviderScope(
            overrides: [
              audioEngineProvider.overrideWith(
                (ref) => TestAudioEngine(
                  const PlaybackState(
                    track: track,
                    position: Duration(seconds: 45),
                    duration: Duration(seconds: 224),
                    outputLabel: 'System default',
                  ),
                ),
              ),
            ],
            child: const Scaffold(body: PlayerPanel(track: track)),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Harder Better Faster Stronger'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('Discovery (2001)'), findsOneWidget);
      expect(find.text('FLAC · 24-bit · 96 kHz'), findsOneWidget);
      expect(find.text('Key: F# Minor  ·  Tempo: 123 BPM'), findsOneWidget);
      expect(find.text('Track 4'), findsOneWidget);
      expect(find.text('GBDUW0000055'), findsOneWidget);
      expect(find.text('℗ 2001 Daft Life Limited'), findsOneWidget);
      expect(find.byType(TrackArtwork), findsOneWidget);
    },
  );
}
