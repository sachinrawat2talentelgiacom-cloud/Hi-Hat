import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio_engine.dart';
import '../../core/theme.dart';
import '../../core/scroll_behavior.dart';
import '../../services/lyrics_service.dart';
import '../../services/lyrics_romanization_service.dart';
import '../../services/lyrics_translation_service.dart';
import '../../services/track_playback_coordinator.dart';
import '../../widgets/track_artwork.dart';
import 'song_actions.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  bool mobileLyricsMode = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioEngineProvider);
    final track = state.track;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () =>
            ref.read(audioEngineProvider.notifier).toggle(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            ref.read(audioEngineProvider.notifier).previous(),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            ref.read(audioEngineProvider.notifier).next(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF020A0F),
          body: track == null
              ? const Center(child: Text('Nothing is playing.'))
              : LayoutBuilder(
                  builder: (context, constraints) => _PlayerStage(
                    state: state,
                    maxWidth: constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                    mobileLyricsMode: mobileLyricsMode,
                    onMobileModeChanged: (lyrics) =>
                        setState(() => mobileLyricsMode = lyrics),
                  ),
                ),
        ),
      ),
    );
  }
}

class _PlayerStage extends StatelessWidget {
  const _PlayerStage({
    required this.state,
    required this.maxWidth,
    required this.maxHeight,
    required this.mobileLyricsMode,
    required this.onMobileModeChanged,
  });

  final PlaybackState state;
  final double maxWidth;
  final double maxHeight;
  final bool mobileLyricsMode;
  final ValueChanged<bool> onMobileModeChanged;

  @override
  Widget build(BuildContext context) {
    final wide = maxWidth >= 860;
    if (!wide) {
      return _MobilePlayerStage(
        state: state,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        lyricsMode: mobileLyricsMode,
        onModeChanged: onMobileModeChanged,
      );
    }
    return _DesktopReferencePlayer(state: state);
  }
}

class _MobilePlayerStage extends StatelessWidget {
  const _MobilePlayerStage({
    required this.state,
    required this.maxWidth,
    required this.maxHeight,
    required this.lyricsMode,
    required this.onModeChanged,
  });

  final PlaybackState state;
  final double maxWidth;
  final double maxHeight;
  final bool lyricsMode;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final shortLandscape = maxHeight < 520 && maxWidth > maxHeight;
    if (shortLandscape) {
      return SafeArea(child: _MobileLandscapePlayer(state: state));
    }
    final horizontal = maxWidth < 360 ? 16.0 : 24.0;
    final heightBasedArtSize = (maxHeight * .455).clamp(210.0, 370.0);
    final portraitArtSize = math.min(
      maxWidth - (horizontal * 2),
      heightBasedArtSize,
    );
    return Stack(
      key: const ValueKey('mobile-player-stage'),
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          key: const ValueKey('mobile-blurred-cover'),
          imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Transform.scale(
            scale: 1.14,
            child: TrackArtwork(
              artworkUrl:
                  state.track!.highResArtworkUrl ?? state.track!.artworkUrl,
              highRes: true,
              iconSize: 72,
              borderRadius: BorderRadius.zero,
              showBorder: false,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: lyricsMode
                  ? const [Color(0x92020A0F), Color(0xC2020A0F)]
                  : const [Color(0xBC020A0F), Color(0xCA020A0F)],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 29),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, 8),
                      child: _MobileModeSwitch(
                        lyrics: lyricsMode,
                        onChanged: onModeChanged,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        tooltip: 'Queue',
                        onPressed: () => showQueue(context),
                        icon: const Icon(Icons.queue_music_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: lyricsMode
                      ? _MobileLyricsMode(
                          key: const ValueKey('mobile-lyrics-section'),
                          state: state,
                        )
                      : Padding(
                          key: const ValueKey('mobile-player-centering-area'),
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            0,
                            horizontal,
                            8,
                          ),
                          child: Center(
                            child: _MobilePortraitPlayer(
                              state: state,
                              artSize: portraitArtSize,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopReferencePlayer extends StatelessWidget {
  const _DesktopReferencePlayer({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context) {
    final track = state.track!;
    final artworkPaneWidth = MediaQuery.sizeOf(context).width * .5375;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF020A0F)),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                key: const ValueKey('desktop-blurred-cover'),
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Transform.scale(
                  scale: 1.10,
                  child: TrackArtwork(
                    key: const ValueKey('desktop-cover-backdrop-source'),
                    artworkUrl: track.highResArtworkUrl ?? track.artworkUrl,
                    highRes: true,
                    iconSize: 120,
                    borderRadius: BorderRadius.zero,
                    showBorder: false,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xA2020A0F), Color(0xCA020A0F)],
                    stops: [0, .76],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              SizedBox(
                key: const ValueKey('full-player-artwork'),
                width: artworkPaneWidth,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TrackArtwork(
                      key: const ValueKey('desktop-cover-layer'),
                      artworkUrl: track.highResArtworkUrl ?? track.artworkUrl,
                      highRes: true,
                      iconSize: 120,
                      borderRadius: BorderRadius.circular(15),
                      showBorder: false,
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: SizedBox.square(
                        key: const ValueKey('desktop-back-button'),
                        dimension: 56,
                        child: Material(
                          color: const Color(0xFF0A2435).withValues(alpha: .82),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Back',
                            padding: EdgeInsets.zero,
                            iconSize: 29,
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(56, 17, 0, 0),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 61,
                        child: LyricsView(
                          key: ValueKey(track.providerTrackId),
                          scrollable: true,
                          immersive: true,
                        ),
                      ),
                      Expanded(
                        flex: 39,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: _DesktopControls(state: state),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopControls extends ConsumerWidget {
  const _DesktopControls({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = state.track!;
    return Column(
      key: const ValueKey('desktop-player-controls'),
      children: [
        const SizedBox(height: 20),
        Text(
          track.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 29,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          track.artist.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF879099),
            fontFamily: 'Inter',
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 21),
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child: _ReferenceProgress(state: state),
        ),
        const SizedBox(height: 75),
        _ReferenceTransport(state: state),
        const Spacer(),
        Row(
          children: [
            IconButton(
              tooltip: 'Repeat ${state.repeatMode.name}',
              onPressed: ref.read(audioEngineProvider.notifier).cycleRepeat,
              icon: Icon(
                state.repeatMode == PlaybackRepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: state.repeatMode == PlaybackRepeatMode.off
                    ? const Color(0xFF7D858B)
                    : Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: state.shuffle ? 'Shuffle on' : 'Shuffle off',
              onPressed: ref.read(audioEngineProvider.notifier).toggleShuffle,
              icon: Icon(
                Icons.shuffle_rounded,
                color: state.shuffle ? Colors.white : const Color(0xFF7D858B),
              ),
            ),
            const Spacer(),
            SizedBox(width: 248, child: _Volume(state: state, compact: true)),
          ],
        ),
      ],
    );
  }
}

class _ReferenceProgress extends ConsumerWidget {
  const _ReferenceProgress({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final max = state.duration.inMilliseconds.toDouble();
    final value = max <= 0
        ? 0.0
        : state.position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    return Column(
      key: const ValueKey('reference-progress'),
      children: [
        SizedBox(
          height: 14,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: const Color(0xFF292B2B),
              trackHeight: 8,
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              max: max <= 0 ? 1 : max,
              onChanged: max <= 0
                  ? null
                  : (next) => ref
                        .read(audioEngineProvider.notifier)
                        .seek(Duration(milliseconds: next.round())),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _time(state.position),
              style: const TextStyle(color: Color(0xFF878C8F)),
            ),
            Text(
              _time(state.duration),
              style: const TextStyle(color: Color(0xFF878C8F)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReferenceTransport extends ConsumerWidget {
  const _ReferenceTransport({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(audioEngineProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Rewind 10 seconds',
          onPressed: () => engine.seekRelative(const Duration(seconds: -10)),
          icon: const Icon(Icons.replay_10_rounded),
        ),
        const SizedBox(width: 26),
        IconButton(
          tooltip: 'Previous',
          onPressed: engine.previous,
          iconSize: 34,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        const SizedBox(width: 35),
        IconButton(
          tooltip: state.playing ? 'Pause' : 'Play',
          onPressed: engine.toggle,
          padding: EdgeInsets.zero,
          icon: state.playing
              ? const _ReferencePauseGlyph()
              : const Icon(Icons.play_arrow_rounded, size: 58),
        ),
        const SizedBox(width: 35),
        IconButton(
          tooltip: 'Next',
          onPressed: engine.next,
          iconSize: 34,
          icon: const Icon(Icons.skip_next_rounded),
        ),
        const SizedBox(width: 26),
        IconButton(
          tooltip: 'Forward 10 seconds',
          onPressed: () => engine.seekRelative(const Duration(seconds: 10)),
          icon: const Icon(Icons.forward_10_rounded),
        ),
      ],
    );
  }
}

class _ReferencePauseGlyph extends StatelessWidget {
  const _ReferencePauseGlyph();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    height: 52,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 13,
          height: 47,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        Container(
          width: 13,
          height: 47,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    ),
  );
}

class _MobileModeSwitch extends StatelessWidget {
  const _MobileModeSwitch({required this.lyrics, required this.onChanged});

  final bool lyrics;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('mobile-mode-switch'),
    width: 150,
    height: 38,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFF20272C),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        _item(context, 'Music', false),
        _item(context, 'Lyrics', true),
      ],
    ),
  );

  Widget _item(BuildContext context, String label, bool value) {
    final selected = lyrics == value;
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(value),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF101417) : Colors.white,
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileLyricsMode extends ConsumerWidget {
  const _MobileLyricsMode({super.key, required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = state.track!;
    final language = ref.watch(_lyricsLanguageProvider(track.providerTrackId));
    return LayoutBuilder(
      builder: (context, constraints) {
        // Match the 360x720 reference composition while still compressing on
        // shorter phones so every playback control remains reachable.
        final lyricsHeight = (constraints.maxHeight * .43).clamp(180.0, 280.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            children: [
              SizedBox(
                height: lyricsHeight,
                child: LyricsView(
                  key: ValueKey('mobile-lyrics-${track.providerTrackId}'),
                  scrollable: true,
                  immersive: true,
                  showHeader: false,
                  compactLines: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _LyricsLanguageSwitch(
                  language: language,
                  width: 270,
                  onChanged: (value) =>
                      ref
                              .read(
                                _lyricsLanguageProvider(track.providerTrackId)
                                    .notifier,
                              )
                              .state =
                          value,
                ),
              ),
              const Spacer(),
              _MobileTrackIdentity(state: state, compact: true),
              const SizedBox(height: 4),
              _MobileProgress(state: state),
              const SizedBox(height: 8),
              _MobileTransport(state: state, compact: true),
              const SizedBox(height: 12),
              _MobilePlaybackStatus(state: state),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}

class _MobilePortraitPlayer extends StatelessWidget {
  const _MobilePortraitPlayer({required this.state, required this.artSize});

  final PlaybackState state;
  final double artSize;

  @override
  Widget build(BuildContext context) {
    final tight = artSize < 280 || MediaQuery.sizeOf(context).width < 370;
    return Column(
      key: const ValueKey('mobile-player-composition'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _MobileArtwork(state: state, size: artSize),
        SizedBox(height: tight ? 10 : 34),
        _MobileTrackIdentity(state: state, compact: tight),
        SizedBox(height: tight ? 2 : 10),
        _MobileProgress(state: state),
        SizedBox(height: tight ? 2 : 28),
        _MobileTransport(state: state, compact: tight),
        SizedBox(height: tight ? 2 : 54),
        _MobilePlaybackStatus(state: state),
      ],
    );
  }
}

class _MobileLandscapePlayer extends StatelessWidget {
  const _MobileLandscapePlayer({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight);
            return Center(
              child: _MobileArtwork(state: state, size: size),
            );
          },
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        flex: 7,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MobileTrackIdentity(state: state, compact: true),
                const SizedBox(height: 8),
                _MobileProgress(state: state),
                const SizedBox(height: 4),
                _MobileTransport(state: state, compact: true),
                const SizedBox(height: 4),
                _MobilePlaybackStatus(state: state),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _MobileArtwork extends StatelessWidget {
  const _MobileArtwork({required this.state, required this.size});

  final PlaybackState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final track = state.track!;
    return SizedBox.square(
      dimension: size,
      child: TrackArtwork(
        key: const ValueKey('full-player-artwork'),
        artworkUrl: track.highResArtworkUrl ?? track.artworkUrl,
        highRes: true,
        iconSize: math.min(72, size * .24),
        borderRadius: BorderRadius.circular(14),
        showBorder: false,
      ),
    );
  }
}

class _MobileTrackIdentity extends StatelessWidget {
  const _MobileTrackIdentity({required this.state, this.compact = false});

  final PlaybackState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final track = state.track!;
    return Semantics(
      container: true,
      label: '${track.displayTitle} by ${track.artist}',
      child: Column(
        children: [
          Text(
            track.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style:
                (compact
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineMedium)
                    ?.copyWith(
                      color: HiHatColors.mineral,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 19 : 24,
                      height: 1.15,
                    ),
          ),
          const SizedBox(height: 4),
          Text(
            track.artist.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: const Color(0xFF7C858D), letterSpacing: .4),
          ),
        ],
      ),
    );
  }
}

class _MobileProgress extends ConsumerWidget {
  const _MobileProgress({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final max = state.duration.inMilliseconds.toDouble();
    final value = max <= 0
        ? 0.0
        : state.position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    return Column(
      children: [
        SizedBox(
          height: 28,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: const Color(0xFF282A2B),
              trackHeight: 8,
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              label: 'Playback position',
              value: value,
              max: max <= 0 ? 1 : max,
              onChanged: max <= 0
                  ? null
                  : (next) => ref
                        .read(audioEngineProvider.notifier)
                        .seek(Duration(milliseconds: next.round())),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_time(state.position), style: _mobileTimeStyle(context)),
              Text(_time(state.duration), style: _mobileTimeStyle(context)),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle? _mobileTimeStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium
      ?.copyWith(
        color: HiHatColors.trace,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class _MobileTransport extends ConsumerWidget {
  const _MobileTransport({required this.state, this.compact = false});

  final PlaybackState state;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(audioEngineProvider.notifier);
    final primarySize = compact ? 48.0 : 72.0;
    final gap = compact ? 0.0 : 14.0;
    return SizedBox(
      key: const ValueKey('mobile-player-transport'),
      height: primarySize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MobileTransportButton(
            tooltip: 'Rewind 10 seconds',
            icon: Icons.replay_10_rounded,
            onPressed: () => engine.seekRelative(const Duration(seconds: -10)),
          ),
          SizedBox(width: gap),
          _MobileTransportButton(
            tooltip: 'Previous',
            icon: Icons.skip_previous_rounded,
            onPressed: engine.previous,
          ),
          SizedBox(width: gap),
          Tooltip(
            message: state.playing ? 'Pause' : 'Play',
            child: Semantics(
              button: true,
              label: state.playing ? 'Pause' : 'Play',
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  minimumSize: Size.square(primarySize),
                ),
                onPressed: engine.toggle,
                child: state.playing
                    ? const _MobilePauseGlyph()
                    : Icon(Icons.play_arrow_rounded, size: compact ? 32 : 38),
              ),
            ),
          ),
          SizedBox(width: gap),
          _MobileTransportButton(
            tooltip: 'Next',
            icon: Icons.skip_next_rounded,
            onPressed: engine.next,
          ),
          SizedBox(width: gap),
          _MobileTransportButton(
            tooltip: 'Forward 10 seconds',
            icon: Icons.forward_10_rounded,
            onPressed: () => engine.seekRelative(const Duration(seconds: 10)),
          ),
        ],
      ),
    );
  }
}

class _MobilePauseGlyph extends StatelessWidget {
  const _MobilePauseGlyph();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 25,
    height: 34,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 8,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: 8,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    ),
  );
}

class _MobileTransportButton extends StatelessWidget {
  const _MobileTransportButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    style: IconButton.styleFrom(
      minimumSize: const Size.square(48),
      foregroundColor: HiHatColors.mineral,
    ),
    onPressed: onPressed,
    icon: Icon(icon, size: 27),
  );
}

class _MobilePlaybackStatus extends ConsumerWidget {
  const _MobilePlaybackStatus({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(audioEngineProvider.notifier);
    return SizedBox(
      key: const ValueKey('mobile-player-status'),
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Repeat ${state.repeatMode.name}',
            isSelected: state.repeatMode != PlaybackRepeatMode.off,
            onPressed: engine.cycleRepeat,
            icon: Icon(
              state.repeatMode == PlaybackRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: state.repeatMode != PlaybackRepeatMode.off
                  ? Colors.white
                  : HiHatColors.trace,
            ),
          ),
          IconButton(
            tooltip: state.shuffle ? 'Turn shuffle off' : 'Turn shuffle on',
            isSelected: state.shuffle,
            onPressed: engine.toggleShuffle,
            icon: Icon(
              Icons.shuffle_rounded,
              color: state.shuffle ? Colors.white : HiHatColors.trace,
            ),
          ),
          const Spacer(),
          Semantics(
            label:
                'Verified source ${_mobileQuality(state)}. Output ${state.outputLabel}',
            child: SizedBox(
              width: 190,
              child: _Volume(state: state, compact: true),
            ),
          ),
        ],
      ),
    );
  }
}

String _mobileQuality(PlaybackState state) {
  final quality = state.track!.quality;
  final parts = <String>[
    if (quality.codec != null && quality.codec!.isNotEmpty)
      quality.codec!.toUpperCase()
    else if (quality.lossless)
      'Lossless'
    else
      'Local file',
    if (quality.bitDepth != null && quality.bitDepth! > 0)
      '${quality.bitDepth}-bit',
    if (quality.sampleRate != null && quality.sampleRate! > 0)
      '${(quality.sampleRate! / 1000).toStringAsFixed(quality.sampleRate! % 1000 == 0 ? 0 : 1)} kHz',
  ];
  return parts.join(' / ');
}

// Kept as the compact/legacy deck implementation for downstream integrations.
// ignore: unused_element
class _ControlDeck extends StatelessWidget {
  const _ControlDeck({
    required this.state,
    required this.compact,
    required this.height,
  });

  final PlaybackState state;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('full-player-control-deck'),
    height: height,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: HiHatColors.trace.withValues(alpha: .42)),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 12)),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        _Progress(state: state, deck: true),
        Expanded(
          child: compact
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Transport(state: state),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_time(state.position)} / ${_time(state.duration)}',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ),
                          SizedBox(
                            width: 112,
                            child: _Volume(state: state, compact: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: constraints.maxWidth * .105,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: _time(state.position)),
                                TextSpan(
                                  text: '  /  ${_time(state.duration)}',
                                  style: const TextStyle(
                                    color: HiHatColors.trace,
                                  ),
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                      ),
                      Center(child: _Transport(state: state)),
                      Positioned(
                        right: constraints.maxWidth * .105,
                        width: 260,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _Volume(state: state, compact: true),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}

class _Progress extends ConsumerWidget {
  const _Progress({required this.state, this.deck = false});
  final PlaybackState state;
  final bool deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final max = state.duration.inMilliseconds.toDouble();
    if (deck) {
      return SizedBox(
        height: 4,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: SliderComponentShape.noThumb,
            overlayShape: SliderComponentShape.noOverlay,
            inactiveTrackColor: HiHatColors.trace.withValues(alpha: .32),
          ),
          child: Slider(
            label: 'Playback position',
            value: max <= 0
                ? 0
                : state.position.inMilliseconds
                      .clamp(0, max.toInt())
                      .toDouble(),
            max: max <= 0 ? 1 : max,
            onChanged: max <= 0
                ? null
                : (value) => ref
                      .read(audioEngineProvider.notifier)
                      .seek(Duration(milliseconds: value.round())),
          ),
        ),
      );
    }
    return Column(
      children: [
        Slider(
          label: 'Playback position',
          value: max <= 0
              ? 0
              : state.position.inMilliseconds.clamp(0, max.toInt()).toDouble(),
          max: max <= 0 ? 1 : max,
          onChanged: max <= 0
              ? null
              : (v) => ref
                    .read(audioEngineProvider.notifier)
                    .seek(Duration(milliseconds: v.round())),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_time(state.position)),
              Text(_time(state.duration)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Transport extends ConsumerWidget {
  const _Transport({required this.state});
  final PlaybackState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: state.shuffle ? 'Shuffle on' : 'Shuffle off',
          isSelected: state.shuffle,
          onPressed: ref.read(audioEngineProvider.notifier).toggleShuffle,
          icon: Icon(
            Icons.shuffle_rounded,
            color: state.shuffle ? HiHatColors.coral : HiHatColors.trace,
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          tooltip: 'Rewind 10 seconds',
          iconSize: 28,
          onPressed: () => ref
              .read(audioEngineProvider.notifier)
              .seekRelative(const Duration(seconds: -10)),
          icon: const Icon(Icons.replay_10_rounded, color: HiHatColors.trace),
        ),
        const SizedBox(width: 24),
        _RoundTransportButton(
          tooltip: 'Previous',
          icon: Icons.skip_previous_rounded,
          onPressed: ref.read(audioEngineProvider.notifier).previous,
        ),
        const SizedBox(width: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: HiHatColors.chamberRaised,
            foregroundColor: HiHatColors.signal,
            shape: const CircleBorder(),
            minimumSize: const Size.square(64),
            side: BorderSide(color: HiHatColors.signal.withValues(alpha: .22)),
          ),
          onPressed: ref.read(audioEngineProvider.notifier).toggle,
          child: Icon(
            state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 36,
          ),
        ),
        const SizedBox(width: 24),
        _RoundTransportButton(
          tooltip: 'Next',
          icon: Icons.skip_next_rounded,
          onPressed: ref.read(audioEngineProvider.notifier).next,
        ),
        const SizedBox(width: 24),
        IconButton(
          tooltip: 'Forward 10 seconds',
          iconSize: 28,
          onPressed: () => ref
              .read(audioEngineProvider.notifier)
              .seekRelative(const Duration(seconds: 10)),
          icon: const Icon(Icons.forward_10_rounded, color: HiHatColors.trace),
        ),
        const SizedBox(width: 24),
        IconButton(
          tooltip: 'Repeat ${state.repeatMode.name}',
          isSelected: state.repeatMode != PlaybackRepeatMode.off,
          onPressed: ref.read(audioEngineProvider.notifier).cycleRepeat,
          icon: Icon(
            state.repeatMode == PlaybackRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: state.repeatMode != PlaybackRepeatMode.off
                ? HiHatColors.coral
                : HiHatColors.trace,
          ),
        ),
      ],
    ),
  );
}

class _RoundTransportButton extends StatelessWidget {
  const _RoundTransportButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: HiHatColors.chamberRaised,
    ),
    child: IconButton(
      tooltip: tooltip,
      iconSize: 34,
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
    ),
  );
}

class _Volume extends ConsumerWidget {
  const _Volume({required this.state, this.compact = false});
  final PlaybackState state;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final control = Row(
      children: [
        IconButton(
          tooltip: state.muted ? 'Unmute' : 'Mute',
          visualDensity: compact ? VisualDensity.compact : null,
          onPressed: ref.read(audioEngineProvider.notifier).toggleMute,
          icon: Icon(
            state.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: compact
                ? SliderTheme.of(context).copyWith(
                    thumbShape: SliderComponentShape.noThumb,
                    overlayShape: SliderComponentShape.noOverlay,
                    trackHeight: 4,
                  )
                : SliderTheme.of(context),
            child: Slider(
              value: state.volume,
              onChanged: ref.read(audioEngineProvider.notifier).setVolume,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      label: 'Volume ${(state.volume * 100).round()} percent',
      child: compact
          ? control
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
                  child: Row(
                    children: [
                      Text(
                        'OUTPUT LEVEL',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const Spacer(),
                      Text('${(state.volume * 100).round()}%'),
                    ],
                  ),
                ),
                control,
              ],
            ),
    );
  }
}

class _LyricsLanguageSwitch extends StatelessWidget {
  const _LyricsLanguageSwitch({
    required this.language,
    required this.onChanged,
    this.width = 181,
    this.height = 38,
    this.padding = 3,
    this.fontSize,
  });

  final _LyricsLanguage language;
  final ValueChanged<_LyricsLanguage> onChanged;
  final double width;
  final double height;
  final double padding;
  final double? fontSize;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('lyrics-language-switch'),
    width: width,
    height: height,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: const Color(0xFF20262B),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        _segment(context, label: 'Original', value: _LyricsLanguage.japanese),
        _segment(context, label: 'Translated', value: _LyricsLanguage.english),
        _segment(context, label: 'Romaji', value: _LyricsLanguage.romaji),
      ],
    ),
  );

  Widget _segment(
    BuildContext context, {
    required String label,
    required _LyricsLanguage value,
  }) {
    final selected = language == value;
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(value),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? const Color(0xFF101417) : Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({
    super.key,
    this.scrollable = false,
    this.immersive = false,
    this.showHeader = true,
    this.compactLines = false,
    this.compactPanel = false,
  });

  final bool scrollable;
  final bool immersive;
  final bool showHeader;
  final bool compactLines;
  final bool compactPanel;

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final scrollController = SmoothScrollController(debugLabel: 'lyrics');
  final lineKeys = <int, GlobalKey>{};
  int lastActiveLine = -2;

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void followActiveLine(BuildContext context, int active) {
    if (!widget.immersive || active < 0 || active == lastActiveLine) return;
    final initialPosition = lastActiveLine == -2;
    lastActiveLine = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lineContext = lineKeys[active]?.currentContext;
      if (lineContext == null) return;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final duration = reduceMotion || initialPosition
          ? Duration.zero
          : const Duration(milliseconds: 700);
      final renderObject = lineContext.findRenderObject();
      if (widget.scrollable &&
          scrollController.hasClients &&
          renderObject != null) {
        scrollController.position.ensureVisible(
          renderObject,
          alignment: .5,
          duration: duration,
          curve: Curves.easeInOutCubic,
        );
      } else {
        Scrollable.ensureVisible(
          lineContext,
          alignment: .5,
          duration: duration,
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Widget syncedLine(
    BuildContext context, {
    required int index,
    required int active,
    required String text,
  }) {
    final lineDistance = active < 0 ? 0 : (index - active).abs();
    final blur = !widget.immersive || lineDistance == 0
        ? 0.0
        : math.min(5.0, .45 + (lineDistance * .72));
    final inactiveOpacity = lineDistance <= 1
        ? .46
        : lineDistance == 2
        ? .38
        : lineDistance == 3
        ? .30
        : lineDistance == 4
        ? .23
        : .17;
    final isActive = index == active;
    return Padding(
      key: lineKeys.putIfAbsent(index, GlobalKey.new),
      padding: EdgeInsets.symmetric(
        vertical: widget.compactPanel ? 4 : (widget.immersive ? 10 : 5),
      ),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Text(
          text,
          textAlign: widget.immersive || widget.compactPanel
              ? TextAlign.left
              : TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: widget.compactPanel
                ? 14.3
                : widget.compactLines
                ? (isActive ? 26 : 25)
                : widget.immersive
                ? 40
                : (isActive ? 19 : 16),
            height: widget.compactPanel
                ? 1.25
                : widget.compactLines
                ? 1.16
                : (widget.immersive ? 1.25 : null),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive
                ? (widget.immersive
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary)
                : (widget.immersive
                      ? Colors.white.withValues(alpha: inactiveOpacity)
                      : null),
          ),
        ),
      ),
    );
  }

  Widget immersivePlainLyrics(
    BuildContext context,
    String value,
    PlaybackState playback,
  ) {
    final lines = value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) return const SizedBox.shrink();
    final durationMs = playback.duration.inMilliseconds;
    final positionMs = playback.position.inMilliseconds;
    final active = durationMs <= 0
        ? 0
        : ((positionMs / durationMs) * lines.length).floor().clamp(
            0,
            lines.length - 1,
          );
    followActiveLine(context, active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          syncedLine(context, index: i, active: active, text: lines[i]),
      ],
    );
  }

  Widget immersiveTranslatedLyrics(
    BuildContext context,
    String value,
    LyricsResult? original,
    PlaybackState playback,
  ) {
    final lines = value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) return const SizedBox.shrink();
    if (original == null || original.synced.isEmpty) {
      return immersivePlainLyrics(context, value, playback);
    }

    final timestamps = List<Duration>.generate(lines.length, (index) {
      if (lines.length == 1 || original.synced.length == 1) {
        return original.synced.first.time;
      }
      final sourceIndex =
          (index * (original.synced.length - 1) / (lines.length - 1)).round();
      return original.synced[sourceIndex].time;
    });
    var active = -1;
    for (var i = 0; i < timestamps.length; i++) {
      if (timestamps[i] <= playback.position) active = i;
    }
    followActiveLine(context, active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          syncedLine(context, index: i, active: active, text: lines[i]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(audioEngineProvider);
    final track = playback.track;
    if (track == null) return const SizedBox.shrink();
    final language = ref.watch(_lyricsLanguageProvider(track.providerTrackId));
    final originalLyrics = language == _LyricsLanguage.japanese
        ? null
        : ref.watch(lyricsProvider(track)).asData?.value;
    final lyricsContent = switch (language) {
      _LyricsLanguage.english =>
        ref
            .watch(englishLyricsProvider(track))
            .when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                error is LyricsTranslationException
                    ? error.message
                    : 'The English translation could not be loaded.',
              ),
              data: (translation) {
                if (translation == null) {
                  return const Text('These lyrics are already in English.');
                }
                if (widget.immersive) {
                  return immersiveTranslatedLyrics(
                    context,
                    translation.text,
                    originalLyrics,
                    playback,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(
                      translation.text,
                      style: TextStyle(
                        fontSize: widget.compactPanel ? 14.3 : null,
                        height: widget.compactPanel ? 1.4 : 1.65,
                        fontWeight: widget.compactPanel
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                    if (!widget.compactPanel) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Translated online with DeepL. Machine translations may miss wordplay or cultural context.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                );
              },
            ),
      _LyricsLanguage.romaji =>
        ref
            .watch(romajiLyricsProvider(track))
            .when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) =>
                  const Text('The Romaji lyrics could not be generated.'),
              data: (romaji) {
                if (romaji == null || romaji.trim().isEmpty) {
                  return const Text(
                    'Romaji lyrics are not available for this song.',
                  );
                }
                if (widget.immersive) {
                  return immersiveTranslatedLyrics(
                    context,
                    romaji,
                    originalLyrics,
                    playback,
                  );
                }
                return SelectableText(
                  romaji,
                  style: TextStyle(
                    fontSize: widget.compactPanel ? 14.3 : null,
                    height: widget.compactPanel ? 1.4 : 1.65,
                    fontWeight: widget.compactPanel ? FontWeight.w600 : null,
                  ),
                );
              },
            ),
      _LyricsLanguage.japanese =>
        ref
            .watch(lyricsProvider(track))
            .when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Text(
                'Lyrics could not be loaded. Check your connection and try again.',
              ),
              data: (lyrics) {
                if (lyrics == null) {
                  return const Text('Lyrics are not available for this song.');
                }
                if (lyrics.synced.isEmpty) {
                  if (widget.immersive) {
                    return immersivePlainLyrics(
                      context,
                      lyrics.plain,
                      playback,
                    );
                  }
                  return SelectableText(
                    lyrics.plain,
                    style: TextStyle(
                      fontSize: widget.compactPanel ? 14.3 : null,
                      height: widget.compactPanel ? 1.4 : 1.65,
                      fontWeight: widget.compactPanel ? FontWeight.w600 : null,
                    ),
                  );
                }
                var active = -1;
                for (var i = 0; i < lyrics.synced.length; i++) {
                  if (lyrics.synced[i].time <= playback.position) active = i;
                }
                followActiveLine(context, active);
                return Column(
                  crossAxisAlignment: widget.immersive || widget.compactPanel
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    for (var i = 0; i < lyrics.synced.length; i++)
                      syncedLine(
                        context,
                        index: i,
                        active: active,
                        text: lyrics.synced[i].text,
                      ),
                    if (!widget.immersive && !widget.compactPanel) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Lyrics provided by LRCLIB',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                );
              },
            ),
    };
    final header = LayoutBuilder(
      builder: (context, constraints) {
        final title = Padding(
          padding: EdgeInsets.only(top: widget.immersive ? 8 : 0),
          child: Text(
            widget.immersive || widget.compactPanel ? 'LYRICS' : 'Lyrics',
            style: widget.compactPanel
                ? const TextStyle(
                    color: Color(0xFF727A73),
                    fontFamily: 'Inter',
                    fontSize: 10.4,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  )
                : Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: widget.immersive ? Colors.white : null,
                    fontWeight: widget.immersive ? FontWeight.w400 : null,
                    fontSize: widget.immersive ? 16 : null,
                    letterSpacing: widget.immersive ? 4.2 : null,
                  ),
          ),
        );
        void selectLanguage(_LyricsLanguage value) =>
            ref
                    .read(
                      _lyricsLanguageProvider(track.providerTrackId).notifier,
                    )
                    .state =
                value;
        final Widget languageSelector = widget.compactPanel
            ? _LyricsLanguageSwitch(
                language: language,
                width: 278.4,
                height: 33.6,
                padding: 2.4,
                fontSize: 12,
                onChanged: selectLanguage,
              )
            : widget.immersive
            ? _LyricsLanguageSwitch(
                language: language,
                width: widget.compactLines ? 270 : 286,
                onChanged: selectLanguage,
              )
            : SegmentedButton<_LyricsLanguage>(
                segments: const [
                  ButtonSegment(
                    value: _LyricsLanguage.japanese,
                    label: Text('Original'),
                  ),
                  ButtonSegment(
                    value: _LyricsLanguage.english,
                    label: Text('Translated'),
                  ),
                  ButtonSegment(
                    value: _LyricsLanguage.romaji,
                    label: Text('Romaji'),
                  ),
                ],
                selected: {language},
                onSelectionChanged: (selection) =>
                    selectLanguage(selection.first),
              );
        if (constraints.maxWidth < 360 && !widget.compactPanel) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 8), languageSelector],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            languageSelector,
            if (widget.immersive && !widget.compactPanel) ...[
              const SizedBox(width: 26),
              Transform.translate(
                offset: const Offset(0, -5),
                child: IconButton(
                  tooltip: 'Queue',
                  onPressed: () => showQueue(context),
                  icon: const Icon(Icons.queue_music_rounded),
                ),
              ),
            ],
          ],
        );
      },
    );
    final lyricsBody = Padding(
      padding: widget.compactPanel
          ? EdgeInsets.zero
          : const EdgeInsets.only(right: 12, bottom: 80),
      child: lyricsContent,
    );

    if (widget.immersive && widget.scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[header, const SizedBox(height: 25)],
          Expanded(
            child: LayoutBuilder(
              builder: (context, viewport) => ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, .14, .36, .82, 1],
                ).createShader(bounds),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    primary: false,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          key: const ValueKey('lyrics-leading-space'),
                          height: viewport.maxHeight * .46,
                        ),
                        lyricsBody,
                        SizedBox(
                          key: const ValueKey('lyrics-trailing-space'),
                          height: viewport.maxHeight * .46,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SizedBox(height: widget.compactPanel ? 10.4 : 12),
        lyricsBody,
      ],
    );
    if (!widget.scrollable) return content;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: scrollController,
        primary: false,
        physics: const ClampingScrollPhysics(),
        child: content,
      ),
    );
  }
}

enum _LyricsLanguage { japanese, romaji, english }

final _lyricsLanguageProvider = StateProvider.family<_LyricsLanguage, String>(
  (ref, trackId) => _LyricsLanguage.japanese,
);

Future<void> showQueue(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      const FractionallySizedBox(heightFactor: .85, child: QueueView()),
);

class QueueView extends ConsumerWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioEngineProvider);
    final upcomingIndices = List<int>.generate(state.queue.length, (i) => i)
        .where((index) => !state.relatedAutoplay || index > state.currentIndex)
        .toList(growable: false);
    return SafeArea(
      child: Column(
        children: [
          ListTile(
            title: Text(
              state.relatedAutoplay ? 'Related up next' : 'Playback queue',
            ),
            subtitle: Text(
              state.relatedAutoplay
                  ? '${upcomingIndices.length} songs related to ${state.track?.artist ?? 'what is playing'}'
                  : '${state.queue.length} songs · Unlimited queue off',
            ),
            trailing: state.relatedAutoplay
                ? TextButton.icon(
                    onPressed: ref
                        .read(audioEngineProvider.notifier)
                        .refreshRelatedQueue,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  )
                : TextButton(
                    onPressed: state.queue.isEmpty
                        ? null
                        : ref.read(audioEngineProvider.notifier).clearQueue,
                    child: const Text('Clear'),
                  ),
          ),
          if (state.track != null && state.relatedAutoplay)
            ListTile(
              leading: const Icon(
                Icons.graphic_eq_rounded,
                color: HiHatColors.signal,
              ),
              title: Text(state.track!.displayTitle),
              subtitle: Text('${state.track!.artist} · Now playing'),
            ),
          if (upcomingIndices.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.relatedAutoplay
                        ? 'No close artist or genre matches were found. Refresh to search again.'
                        : 'Your queue is empty. Add songs from Home, Search, Albums, Library, or playlists.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: upcomingIndices.length,
                itemBuilder: (context, position) {
                  final i = upcomingIndices[position];
                  final t = state.queue[i];
                  return ListTile(
                    key: ValueKey('$i:${t.id}'),
                    leading: Text('${position + 1}'),
                    title: Text(t.displayTitle),
                    subtitle: Text(t.artist),
                    onTap: () async {
                      if (t.isLocal) {
                        await ref.read(audioEngineProvider.notifier).playAt(i);
                      } else if (context.mounted) {
                        await ref
                            .read(trackPlaybackCoordinatorProvider)
                            .play(t, Navigator.of(context));
                      }
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SongActionsButton(track: t),
                        IconButton(
                          tooltip: 'Remove from queue',
                          onPressed: () => ref
                              .read(audioEngineProvider.notifier)
                              .removeAt(i),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

String _time(Duration d) =>
    '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
