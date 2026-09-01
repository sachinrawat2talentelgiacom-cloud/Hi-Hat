import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio_engine.dart';
import '../../core/theme.dart';
import '../../core/scroll_behavior.dart';
import '../../services/lyrics_service.dart';
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
  final mobileLyricsKey = GlobalKey();

  void scrollToMobileLyrics() {
    final lyricsContext = mobileLyricsKey.currentContext;
    if (lyricsContext == null) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Scrollable.ensureVisible(
      lyricsContext,
      alignment: 0,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioEngineProvider);
    final track = state.track;
    final compact = MediaQuery.sizeOf(context).width < 860;
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
          backgroundColor: HiHatColors.chamberSunken,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            toolbarHeight: compact ? 64 : 128,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Now Playing',
              style: TextStyle(
                fontSize: compact ? 16 : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              if (compact)
                IconButton(
                  tooltip: 'Lyrics',
                  onPressed: track == null ? null : scrollToMobileLyrics,
                  icon: const Icon(Icons.lyrics_outlined),
                ),
              Padding(
                padding: EdgeInsets.only(right: compact ? 4 : 15),
                child: IconButton(
                  tooltip: 'Queue',
                  onPressed: () => showQueue(context),
                  icon: const Icon(Icons.queue_music),
                ),
              ),
            ],
          ),
          body: track == null
              ? const Center(child: Text('Nothing is playing.'))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (compact)
                      const ColoredBox(color: HiHatColors.chamberSunken)
                    else ...[
                      TrackArtwork(
                        artworkUrl: track.highResArtworkUrl ?? track.artworkUrl,
                        highRes: true,
                        iconSize: 120,
                        borderRadius: BorderRadius.zero,
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                HiHatColors.chamberSunken.withValues(
                                  alpha: .54,
                                ),
                                HiHatColors.chamberSunken.withValues(
                                  alpha: .70,
                                ),
                                HiHatColors.chamberSunken.withValues(
                                  alpha: .90,
                                ),
                              ],
                              stops: const [0, .62, 1],
                            ),
                          ),
                        ),
                      ),
                    ],
                    SafeArea(
                      top: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) => _PlayerStage(
                          state: state,
                          maxWidth: constraints.maxWidth,
                          maxHeight: constraints.maxHeight,
                          mobileLyricsKey: mobileLyricsKey,
                        ),
                      ),
                    ),
                  ],
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
    required this.mobileLyricsKey,
  });

  final PlaybackState state;
  final double maxWidth;
  final double maxHeight;
  final GlobalKey mobileLyricsKey;

  @override
  Widget build(BuildContext context) {
    final track = state.track!;
    final wide = maxWidth >= 860;
    if (!wide) {
      return _MobilePlayerStage(
        state: state,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        lyricsKey: mobileLyricsKey,
      );
    }
    final horizontalPadding = wide ? 24.0 : 16.0;
    final deckHeight = wide ? 134.0 : 188.0;
    final referenceScale = (maxWidth / 1920).clamp(.72, 1.0).toDouble();
    final contentTop = wide
        ? (maxHeight * .14).clamp(96.0, 152.0).toDouble()
        : MediaQuery.paddingOf(context).top + kToolbarHeight + 16;
    final artSize = wide
        ? math.max(
            160.0,
            math.min(
              620.0,
              math.min(maxWidth * .32, maxHeight - deckHeight - 150),
            ),
          )
        : math.min(300.0, math.min(maxWidth - 40, maxHeight * .32));

    final artworkAndTitle = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: artSize,
          child: TrackArtwork(
            key: const ValueKey('full-player-artwork'),
            artworkUrl: track.highResArtworkUrl ?? track.artworkUrl,
            highRes: true,
            iconSize: 88,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        SizedBox(height: 28 * referenceScale),
        Text(
          track.displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 32 * referenceScale,
          ),
        ),
        const SizedBox.shrink(),
        Text(
          'By ${track.artist}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: HiHatColors.trace,
            fontWeight: FontWeight.w400,
            fontSize: 22 * referenceScale,
          ),
        ),
      ],
    );

    final content = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: maxWidth * .1021),
              SizedBox(width: artSize, child: artworkAndTitle),
              SizedBox(width: maxWidth * .0405),
              Expanded(
                child: LyricsView(
                  key: ValueKey(track.providerTrackId),
                  scrollable: true,
                  immersive: true,
                ),
              ),
              SizedBox(width: maxWidth * .1021),
            ],
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                artworkAndTitle,
                const SizedBox(height: 28),
                SizedBox(
                  height: math.max(260, maxHeight * .46),
                  child: LyricsView(
                    key: ValueKey(track.providerTrackId),
                    scrollable: true,
                    immersive: true,
                  ),
                ),
              ],
            ),
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        contentTop,
        horizontalPadding,
        0,
      ),
      child: Column(
        children: [
          Expanded(child: content),
          const SizedBox(height: 16),
          _ControlDeck(state: state, compact: !wide, height: deckHeight),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}

class _MobilePlayerStage extends StatelessWidget {
  const _MobilePlayerStage({
    required this.state,
    required this.maxWidth,
    required this.maxHeight,
    required this.lyricsKey,
  });

  final PlaybackState state;
  final double maxWidth;
  final double maxHeight;
  final GlobalKey lyricsKey;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final top = math.max(safeTop, 64.0);
    final shortLandscape = maxHeight < 520 && maxWidth > maxHeight;
    final horizontal = maxWidth < 360 ? 14.0 : 20.0;
    final heightBasedArtSize = maxHeight >= 700
        ? 340.0
        : (maxHeight * .33).clamp(168.0, 240.0);
    final portraitArtSize = math.min(
      maxWidth - (horizontal * 2),
      heightBasedArtSize,
    );
    final player = KeyedSubtree(
      key: const ValueKey('mobile-player-stage'),
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontal, top + 4, horizontal, 10),
        child: shortLandscape
            ? _MobileLandscapePlayer(state: state)
            : SizedBox(
                key: const ValueKey('mobile-player-centering-area'),
                child: Center(
                  child: _MobilePortraitPlayer(
                    state: state,
                    artSize: portraitArtSize,
                  ),
                ),
              ),
      ),
    );
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context)
          .copyWith(physics: const ClampingScrollPhysics(), scrollbars: false),
      child: SingleChildScrollView(
        key: const ValueKey('mobile-player-scroll'),
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: maxHeight, child: player),
            Container(
              key: lyricsKey,
              constraints: BoxConstraints(minHeight: math.max(520, maxHeight)),
              padding: EdgeInsets.fromLTRB(
                horizontal,
                math.max(safeTop, 64.0) + 16,
                horizontal,
                16,
              ),
              color: HiHatColors.chamberSunken,
              child: SizedBox(
                key: const ValueKey('mobile-lyrics-section'),
                height: math.max(420, maxHeight - 110),
                child: LyricsView(
                  key: ValueKey(
                    'mobile-lyrics-${state.track!.providerTrackId}',
                  ),
                  scrollable: true,
                  immersive: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobilePortraitPlayer extends StatelessWidget {
  const _MobilePortraitPlayer({required this.state, required this.artSize});

  final PlaybackState state;
  final double artSize;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('mobile-player-composition'),
    mainAxisSize: MainAxisSize.min,
    children: [
      _MobileArtwork(state: state, size: artSize),
      const SizedBox(height: 12),
      _MobileTrackIdentity(state: state),
      const SizedBox(height: 16),
      _MobileProgress(state: state),
      const SizedBox(height: 10),
      _MobileTransport(state: state),
      const SizedBox(height: 10),
      _MobilePlaybackStatus(state: state),
    ],
  );
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
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style:
                (compact
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineMedium)
                    ?.copyWith(
                      color: HiHatColors.mineral,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
          ),
          const SizedBox(height: 4),
          Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: HiHatColors.trace),
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
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              inactiveTrackColor: HiHatColors.trace.withValues(alpha: .34),
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
    final primarySize = compact ? 60.0 : 72.0;
    return SizedBox(
      key: const ValueKey('mobile-player-transport'),
      height: primarySize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MobileTransportButton(
            tooltip: 'Previous',
            icon: Icons.skip_previous_rounded,
            onPressed: engine.previous,
          ),
          _MobileTransportButton(
            tooltip: 'Rewind 10 seconds',
            icon: Icons.replay_10_rounded,
            onPressed: () => engine.seekRelative(const Duration(seconds: -10)),
          ),
          Tooltip(
            message: state.playing ? 'Pause' : 'Play',
            child: Semantics(
              button: true,
              label: state.playing ? 'Pause' : 'Play',
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: HiHatColors.signal,
                  foregroundColor: HiHatColors.onSignal,
                  shape: const CircleBorder(),
                  minimumSize: Size.square(primarySize),
                ),
                onPressed: engine.toggle,
                child: Icon(
                  state.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: compact ? 32 : 38,
                ),
              ),
            ),
          ),
          _MobileTransportButton(
            tooltip: 'Forward 10 seconds',
            icon: Icons.forward_10_rounded,
            onPressed: () => engine.seekRelative(const Duration(seconds: 10)),
          ),
          _MobileTransportButton(
            tooltip: 'Next',
            icon: Icons.skip_next_rounded,
            onPressed: engine.next,
          ),
        ],
      ),
    );
  }
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
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return SizedBox(
      key: const ValueKey('mobile-player-status'),
      height: 52 + ((textScale - 1).clamp(0, 1) * 20),
      child: Row(
        children: [
          IconButton(
            tooltip: state.shuffle ? 'Turn shuffle off' : 'Turn shuffle on',
            isSelected: state.shuffle,
            onPressed: engine.toggleShuffle,
            icon: Icon(
              Icons.shuffle_rounded,
              color: state.shuffle ? HiHatColors.signal : HiHatColors.trace,
            ),
          ),
          Expanded(
            child: Semantics(
              label:
                  'Verified source ${_mobileQuality(state)}. Output ${state.outputLabel}',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: HiHatColors.signal,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _mobileQuality(state),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: HiHatColors.mineral),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.outputLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: HiHatColors.trace),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Repeat ${state.repeatMode.name}',
            isSelected: state.repeatMode != PlaybackRepeatMode.off,
            onPressed: engine.cycleRepeat,
            icon: Icon(
              state.repeatMode == PlaybackRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: state.repeatMode != PlaybackRepeatMode.off
                  ? HiHatColors.signal
                  : HiHatColors.trace,
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
  const _LyricsLanguageSwitch({required this.english, required this.onChanged});

  final bool english;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    width: 181,
    height: 45,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        _segment(context, label: 'Original', value: false),
        _segment(context, label: 'English', value: true),
      ],
    ),
  );

  Widget _segment(
    BuildContext context, {
    required String label,
    required bool value,
  }) {
    final selected = english == value;
    return Expanded(
      child: Material(
        color: selected ? HiHatColors.signal : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(value),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? HiHatColors.onSignal : Colors.white,
                fontWeight: FontWeight.w500,
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
  });

  final bool scrollable;
  final bool immersive;

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
    lastActiveLine = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lineContext = lineKeys[active]?.currentContext;
      if (lineContext == null) return;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final duration = reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220);
      final renderObject = lineContext.findRenderObject();
      if (widget.scrollable &&
          scrollController.hasClients &&
          renderObject != null) {
        scrollController.position.ensureVisible(
          renderObject,
          alignment: .28,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
      } else {
        Scrollable.ensureVisible(
          lineContext,
          alignment: .28,
          duration: duration,
          curve: Curves.easeOutCubic,
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
    final blur = !widget.immersive || lineDistance < 3
        ? 0.0
        : math.min(4.5, (lineDistance - 1) * .8);
    final inactiveOpacity = lineDistance <= 1
        ? .50
        : lineDistance == 2
        ? .38
        : lineDistance == 3
        ? .26
        : .16;
    final isActive = index == active;
    return Padding(
      key: lineKeys.putIfAbsent(index, GlobalKey.new),
      padding: EdgeInsets.symmetric(vertical: widget.immersive ? 10 : 5),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Text(
          text,
          textAlign: widget.immersive ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: widget.immersive ? 40 : (isActive ? 19 : 16),
            height: widget.immersive ? 1.25 : null,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
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
    final showEnglish = ref.watch(
      _showEnglishLyricsProvider(track.providerTrackId),
    );
    final originalLyrics = showEnglish
        ? ref.watch(lyricsProvider(track)).asData?.value
        : null;
    final lyricsContent = showEnglish
        ? ref
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
                        style: const TextStyle(height: 1.65),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Translated online with DeepL. Machine translations may miss wordplay or cultural context.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                },
              )
        : ref
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
                    return const Text(
                      'Lyrics are not available for this song.',
                    );
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
                      style: const TextStyle(height: 1.65),
                    );
                  }
                  var active = -1;
                  for (var i = 0; i < lyrics.synced.length; i++) {
                    if (lyrics.synced[i].time <= playback.position) active = i;
                  }
                  followActiveLine(context, active);
                  return Column(
                    crossAxisAlignment: widget.immersive
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
                      if (!widget.immersive) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Lyrics provided by LRCLIB',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  );
                },
              );
    final header = LayoutBuilder(
      builder: (context, constraints) {
        final title = Text(
          'Lyrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: widget.immersive ? Colors.white : null,
            fontWeight: widget.immersive ? FontWeight.w500 : null,
            fontSize: widget.immersive ? 24 : null,
          ),
        );
        void selectLanguage(bool value) =>
            ref
                    .read(
                      _showEnglishLyricsProvider(track.providerTrackId)
                          .notifier,
                    )
                    .state =
                value;
        final Widget languageSelector = widget.immersive
            ? _LyricsLanguageSwitch(
                english: showEnglish,
                onChanged: selectLanguage,
              )
            : SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Original')),
                  ButtonSegment(value: true, label: Text('English')),
                ],
                selected: {showEnglish},
                onSelectionChanged: (selection) =>
                    selectLanguage(selection.first),
              );
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 8), languageSelector],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            languageSelector,
          ],
        );
      },
    );
    final lyricsBody = Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 80),
      child: lyricsContent,
    );

    if (widget.immersive && widget.scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 34),
          Expanded(
            child: ShaderMask(
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
                  child: lyricsBody,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, const SizedBox(height: 12), lyricsBody],
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

final _showEnglishLyricsProvider = StateProvider.family<bool, String>(
  (ref, trackId) => false,
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
              leading: const Icon(Icons.graphic_eq, color: HiHatColors.signal),
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
                          icon: const Icon(Icons.close),
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
