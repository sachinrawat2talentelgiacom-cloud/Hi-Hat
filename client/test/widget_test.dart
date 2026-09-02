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
import 'package:hi_hat/services/lyrics_romanization_service.dart';
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
      expect(find.byKey(const ValueKey('mobile-mode-switch')), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Lyrics'), findsOneWidget);
      expect(find.byType(TrackArtwork), findsWidgets);
      expect(find.byKey(const ValueKey('mobile-player-stage')), findsOneWidget);
      final centeringArea = tester.getRect(
        find.byKey(const ValueKey('mobile-player-centering-area')),
      );
      final composition = tester.getRect(
        find.byKey(const ValueKey('mobile-player-composition')),
      );
      final topSpace = composition.top - centeringArea.top;
      final bottomSpace = centeringArea.bottom - composition.bottom;
      expect((topSpace - bottomSpace).abs(), lessThanOrEqualTo(10));
      await tester.tap(find.text('Lyrics'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        find.byKey(const ValueKey('mobile-lyrics-section')),
        findsOneWidget,
      );
      final lyrics = tester.widget<LyricsView>(find.byType(LyricsView));
      expect(lyrics.immersive, isTrue);
      expect(lyrics.scrollable, isTrue);
      expect(lyrics.showHeader, isFalse);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byTooltip('Queue'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mobile-player-transport')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mobile-player-status')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(LyricsView),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(engine.state.playing, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobile lyrics player matches the 360x720 reference geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const track = TrackSummary(
      id: 'local:reference-mobile',
      provider: 'local',
      providerTrackId: 'reference-mobile',
      title: 'Reference Mobile Track',
      artist: 'Reference Artist',
      localPath: 'reference-mobile.flac',
    );
    final engine = TestAudioEngine(
      const PlaybackState(
        track: track,
        playing: true,
        position: Duration(minutes: 2),
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
    await tester.tap(find.text('Lyrics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.getRect(find.byKey(const ValueKey('mobile-player-stage'))),
      const Rect.fromLTWH(0, 0, 360, 720),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('mobile-mode-switch'))),
      const Rect.fromLTWH(105, 17, 150, 38),
    );
    expect(
      tester.getRect(find.byType(LyricsView)),
      const Rect.fromLTWH(16, 76, 328, 280),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('lyrics-language-switch'))),
      const Rect.fromLTWH(45, 360, 270, 38),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('mobile-player-status'))),
      const Rect.fromLTWH(16, 666, 328, 48),
    );
    expect(tester.takeException(), isNull);
  });

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
    await tester.tap(find.text('Lyrics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('mobile-player-transport')),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('mobile-player-status'))).bottom,
      lessThanOrEqualTo(568),
    );
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
    final artworkWidget = tester.widget<TrackArtwork>(
      find.byKey(const ValueKey('full-player-artwork')),
    );
    expect(artworkWidget.showBorder, isFalse);
    expect(
      tester.getRect(find.text('Landscape Listening')).top,
      greaterThanOrEqualTo(20),
    );
    expect(artwork.right, lessThan(transport.left));
    expect(transport.bottom, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-screen player lays out the immersive desktop stage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
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
          romajiLyricsProvider.overrideWith(
            (ref, track) async => 'Romaji one\nRomaji two\nRomaji three\nRomaji active line\nRomaji blurred line',
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

    expect(find.text('Desktop Listening Session'), findsOneWidget);
    expect(find.text('HI HAT ARTIST'), findsOneWidget);
    expect(find.text('2:14'), findsOneWidget);
    expect(find.text('3:40'), findsOneWidget);
    expect(find.byType(LyricsView), findsOneWidget);
    expect(find.byType(TrackArtwork), findsNWidgets(2));
    expect(find.byKey(const ValueKey('desktop-cover-layer')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desktop-cover-backdrop-source')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('desktop-blurred-cover')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('desktop-blurred-cover'))),
      const Rect.fromLTWH(0, 0, 1920, 1080),
    );
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('lyrics-leading-space'))).height,
      greaterThan(150),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('lyrics-trailing-space')))
          .height,
      greaterThan(150),
    );
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
      closeTo(.30, .01),
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
    expect(artwork.left, 24);
    expect(artwork.top, 24);
    expect(artwork.width, 1032);
    expect(artwork.bottom, 1056);
    final backButton = tester.getRect(
      find.byKey(const ValueKey('desktop-back-button')),
    );
    expect(backButton, const Rect.fromLTWH(40, 40, 56, 56));
    final languageSwitch = tester.getRect(
      find.byKey(const ValueKey('lyrics-language-switch')),
    );
    expect(languageSwitch, const Rect.fromLTWH(1536, 41, 286, 38));
    final lyricsRect = tester.getRect(find.byType(LyricsView));
    final titleRect = tester.getRect(find.text('Desktop Listening Session'));
    expect(titleRect.top - lyricsRect.bottom, 20);
    expect(
      find.byKey(const ValueKey('desktop-player-controls')),
      findsOneWidget,
    );
    expect(find.text('Romaji'), findsOneWidget);
    await tester.tap(find.text('Romaji'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Romaji active line'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Romaji active line')).style?.fontSize,
      40,
    );
    await tester.tap(find.text('Translated'));
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
      closeTo(.30, .01),
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

    expect(
      Theme.of(tester.element(find.byType(SearchScreen)))
          .textTheme
          .bodyMedium
          ?.fontFamily,
      'Inter',
    );
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
