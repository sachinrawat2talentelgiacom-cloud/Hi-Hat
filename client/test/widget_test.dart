import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hi_hat/core/theme.dart';
import 'package:hi_hat/features/player/player_panel.dart';
import 'package:hi_hat/features/player/full_player_screen.dart';
import 'package:hi_hat/features/search/search_screen.dart';
import 'package:hi_hat/models/track.dart';
import 'package:hi_hat/services/audio_engine.dart';
import 'package:hi_hat/services/lyrics_service.dart';
import 'package:hi_hat/services/lyrics_translation_service.dart';
import 'package:hi_hat/widgets/track_artwork.dart';
import 'package:hi_hat/widgets/brand_widgets.dart';

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
      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.byType(TrackArtwork), findsWidgets);
      expect(find.byKey(const ValueKey('mobile-player-stage')), findsOneWidget);
      final lyrics = tester.widget<LyricsView>(find.byType(LyricsView));
      expect(lyrics.immersive, isTrue);
      expect(lyrics.scrollable, isTrue);
      final headerRect = tester.getRect(find.text('Now Playing'));
      final artworkRect = tester.getRect(
        find.byKey(const ValueKey('full-player-artwork')),
      );
      final statusRect = tester.getRect(
        find.byKey(const ValueKey('mobile-player-status')),
      );
      final lyricsRect = tester.getRect(
        find.byKey(const ValueKey('mobile-lyrics-section')),
      );
      expect(artworkRect.top - headerRect.bottom, inInclusiveRange(16, 40));
      expect(lyricsRect.top - statusRect.bottom, inInclusiveRange(64, 100));
      await tester.drag(
        find.byKey(const ValueKey('mobile-player-scroll')),
        const Offset(0, -700),
      );
      await tester.pump();
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('mobile-lyrics-section')))
            .dy,
        lessThan(300),
      );
      await tester.drag(
        find.byKey(const ValueKey('mobile-player-scroll')),
        const Offset(0, 700),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Lyrics'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('mobile-lyrics-section')))
            .dy,
        lessThan(180),
      );
      expect(
        find.descendant(
          of: find.byType(LyricsView),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      final pageScroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('mobile-player-scroll')),
      );
      expect(pageScroll.physics, isA<ClampingScrollPhysics>());
      expect(engine.state.playing, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobile player keeps controls reachable on a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const track = TrackSummary(
      id: 'local:short-phone',
      provider: 'local',
      providerTrackId: 'short-phone',
      title: 'A Long Track Title That Still Belongs on a Small Phone',
      artist: 'A Long Artist Name',
      localPath: 'short-phone.flac',
      quality: AudioQuality(
        codec: 'FLAC',
        lossless: true,
        bitDepth: 24,
        sampleRate: 96000,
      ),
    );
    final engine = TestAudioEngine(
      const PlaybackState(
        track: track,
        playing: true,
        position: Duration(seconds: 45),
        duration: Duration(minutes: 3, seconds: 30),
        outputLabel: 'System mixed output',
        queue: [track],
        currentIndex: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioEngineProvider.overrideWith((ref) => engine)],
        child: MaterialApp(
          theme: HiHatTheme.dark,
          home: const FullPlayerScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('mobile-player-stage')), findsOneWidget);
    expect(find.text('FLAC / 24-bit / 96 kHz'), findsOneWidget);
    expect(find.text('System mixed output'), findsOneWidget);
    for (final tooltip in [
      'Previous',
      'Rewind 10 seconds',
      'Forward 10 seconds',
      'Next',
    ]) {
      final rect = tester.getRect(find.byTooltip(tooltip));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile player remains usable with large accessibility text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const track = TrackSummary(
      id: 'local:large-text',
      provider: 'local',
      providerTrackId: 'large-text',
      title: 'A Deliberately Long Listening Session Title',
      artist: 'An Artist With A Long Name',
      localPath: 'large-text.flac',
    );
    final engine = TestAudioEngine(
      const PlaybackState(
        track: track,
        duration: Duration(minutes: 4, seconds: 18),
        queue: [track],
        currentIndex: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioEngineProvider.overrideWith((ref) => engine)],
        child: MaterialApp(
          theme: HiHatTheme.dark,
          home: const FullPlayerScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('mobile-player-stage')), findsOneWidget);
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(
      tester.getRect(find.byTooltip('Play')).bottom,
      lessThanOrEqualTo(800),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile player adapts to short landscape', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const track = TrackSummary(
      id: 'local:landscape',
      provider: 'local',
      providerTrackId: 'landscape',
      title: 'Landscape Listening',
      artist: 'Hi Hat Artist',
      localPath: 'landscape.flac',
    );
    final engine = TestAudioEngine(
      const PlaybackState(
        track: track,
        playing: false,
        duration: Duration(minutes: 4),
        queue: [track],
        currentIndex: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioEngineProvider.overrideWith((ref) => engine)],
        child: MaterialApp(
          theme: HiHatTheme.dark,
          home: const FullPlayerScreen(),
        ),
      ),
    );
    await tester.pump();

    final artwork = tester.getRect(
      find.byKey(const ValueKey('full-player-artwork')),
    );
    final transport = tester.getRect(
      find.byKey(const ValueKey('mobile-player-transport')),
    );
    expect(artwork.right, lessThan(transport.left));
    expect(transport.bottom, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-screen player lays out the immersive desktop stage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const track = TrackSummary(
      id: 'local:desktop-player',
      provider: 'local',
      providerTrackId: 'desktop-player',
      title: 'Desktop Listening Session',
      artist: 'Hi Hat Artist',
      localPath: 'desktop-player.flac',
    );
    final engine = TestAudioEngine(
      const PlaybackState(
        track: track,
        playing: true,
        position: Duration(minutes: 2, seconds: 14),
        duration: Duration(minutes: 3, seconds: 40),
        queue: [track],
        currentIndex: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineProvider.overrideWith((ref) => engine),
          lyricsProvider.overrideWith(
            (ref, track) async => const LyricsResult(
              plain: 'Before\nCurrent lyric\nNext lyric\nLater lyric',
              synced: [
                LyricLine(Duration(minutes: 1, seconds: 40), 'Before'),
                LyricLine(Duration(minutes: 1, seconds: 50), 'Current lyric'),
                LyricLine(Duration(minutes: 2), 'Next lyric'),
                LyricLine(Duration(minutes: 2, seconds: 10), 'Later lyric'),
                LyricLine(Duration(minutes: 2, seconds: 20), 'Blurred lyric'),
              ],
            ),
          ),
          englishLyricsProvider.overrideWith(
            (ref, track) async => const TranslatedLyrics(
              text: 'English one\nEnglish two\nEnglish three\nEnglish active line\nEnglish blurred line',
              sourceLanguage: 'ja',
            ),
          ),
        ],
        child: MaterialApp(
          theme: HiHatTheme.dark,
          home: const FullPlayerScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Now Playing'), findsOneWidget);
    expect(find.text('Desktop Listening Session'), findsOneWidget);
    expect(find.text('By Hi Hat Artist'), findsOneWidget);
    expect(find.text('2:14  /  3:40'), findsOneWidget);
    expect(find.byType(LyricsView), findsOneWidget);
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LyricsView),
        matching: find.byType(Scrollbar),
      ),
      findsNothing,
    );
    expect(find.text('Current lyric'), findsOneWidget);
    expect(find.byType(ImageFiltered), findsAtLeastNWidgets(5));
    expect(tester.widget<Text>(find.text('Current lyric')).style?.fontSize, 40);
    expect(
      tester.widget<Text>(find.text('Before')).style?.color?.a,
      closeTo(.26, .01),
    );
    expect(
      tester.widget<Text>(find.text('Later lyric')).style?.fontWeight,
      FontWeight.w700,
    );
    expect(find.text('Autoplay related'), findsNothing);
    expect(find.text('Add to playlist'), findsNothing);
    final artwork = tester.getRect(
      find.byKey(const ValueKey('full-player-artwork')),
    );
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('full-player-artwork')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(artwork.left, closeTo(171, 2));
    expect(artwork.top, closeTo(126, 2));
    expect(artwork.width, closeTo(460.8, 2));
    final controlDeck = tester.getRect(
      find.byKey(const ValueKey('full-player-control-deck')),
    );
    expect(controlDeck.left, 24);
    expect(controlDeck.right, 1416);
    expect(controlDeck.bottom, 875);
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('English active line'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('English active line')).style?.fontSize,
      40,
    );
    expect(
      tester.widget<Text>(find.text('English active line')).style?.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text('English one')).style?.color?.a,
      closeTo(.26, .01),
    );
    expect(tester.takeException(), isNull);
  });

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

    expect(find.text('Find. Verify. Own.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Find a track, artist, or album'), findsOneWidget);
    expect(find.text('Find it once. Keep the verified file.'), findsOneWidget);

    final field = tester.getRect(find.byType(TextField));
    final icon = tester.getRect(find.byIcon(Icons.search_rounded));
    expect((field.center.dy - icon.center.dy).abs(), lessThan(1));
  });

  testWidgets('brand mark and lockup expose one coherent identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: HiHatTheme.dark,
        home: const Scaffold(
          body: Column(
            children: [
              HiHatMark(semanticLabel: 'Hi Hat'),
              HiHatLockup(),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Hi Hat'), findsOneWidget);
    expect(find.text('HI HAT'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
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

  testWidgets('PlayerPanel displays only essential local-file metadata', (
    tester,
  ) async {
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
    expect(find.text('SOURCE'), findsOneWidget);
    expect(find.text('FLAC · 24-bit · 96 kHz'), findsOneWidget);
    expect(find.text('OWNED FILE'), findsNWidgets(2));
    expect(
      find.text(
        r'C:\Music\Daft Punk\Discovery\04. Harder Better Faster Stronger.flac',
      ),
      findsOneWidget,
    );
    expect(find.text('LOCAL ARCHIVE'), findsOneWidget);
    expect(find.text('32.9 MB  ·  FLAC lossless'), findsOneWidget);
    expect(find.text('ACOUSTIC PROPERTIES'), findsNothing);
    expect(find.text('CATALOG INFO'), findsNothing);
    expect(find.text('ISRC IDENTIFIER'), findsNothing);
    expect(find.text('COPYRIGHT / RELEASE'), findsNothing);
    expect(find.byType(TrackArtwork), findsOneWidget);
  });
}
