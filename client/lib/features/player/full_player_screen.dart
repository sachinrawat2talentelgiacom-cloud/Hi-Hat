import 'dart:math' as math;

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

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          appBar: AppBar(
            title: const Text('Now playing'),
            actions: [
              IconButton(
                tooltip: 'Queue',
                onPressed: () => showQueue(context),
                icon: const Icon(Icons.queue_music),
              ),
            ],
          ),
          extendBodyBehindAppBar: false,
          body: track == null
              ? const Center(child: Text('Nothing is playing.'))
              : SafeArea(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final tokens = Theme.of(context)
                          .extension<HiHatTokens>()!;
                      final wide = c.maxWidth >= 760;
                      final horizontalPadding = wide
                          ? tokens.spaceXl
                          : tokens.spaceMd;
                      final availableWidth =
                          c.maxWidth - (horizontalPadding * 2);
                      final artSize = wide
                          ? math.min(
                              440.0,
                              math.min(
                                (availableWidth - 48) / 2,
                                c.maxHeight - tokens.spaceLg - tokens.spaceXl,
                              ),
                            )
                          : math.min(
                              300.0,
                              math.min(availableWidth, c.maxHeight * .26),
                            );
                      final art = SizedBox.square(
                        dimension: artSize,
                        child: TrackArtwork(
                          artworkUrl: track.highResArtworkUrl,
                          highRes: true,
                          iconSize: 90,
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                        ),
                      );
                      final details = Card(
                        child: Padding(
                          padding: EdgeInsets.all(tokens.spaceLg),
                          child: Column(
                            children: [
                              Text(
                                track.displayTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                track.artist,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              _Progress(state: state),
                              _Transport(state: state),
                              _Volume(state: state),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: [
                                  FilterChip(
                                    label: const Text('Autoplay related'),
                                    selected: state.relatedAutoplay,
                                    onSelected: ref
                                        .read(audioEngineProvider.notifier)
                                        .setRelatedAutoplay,
                                  ),
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.playlist_add,
                                      size: 18,
                                    ),
                                    label: const Text('Add to playlist'),
                                    onPressed: () =>
                                        showAddToPlaylist(context, ref, track),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: LyricsView(
                                  key: ValueKey(track.providerTrackId),
                                  scrollable: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          tokens.spaceLg,
                          horizontalPadding,
                          tokens.spaceXl,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(-.7, -.8),
                              radius: 1.4,
                              colors: [
                                Theme.of(context).colorScheme.primary
                                    .withValues(alpha: .12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    art,
                                    const SizedBox(width: 48),
                                    Expanded(child: details),
                                  ],
                                )
                              : Column(
                                  children: [
                                    art,
                                    SizedBox(height: tokens.spaceMd),
                                    Expanded(child: details),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _Progress extends ConsumerWidget {
  const _Progress({required this.state});
  final PlaybackState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final max = state.duration.inMilliseconds.toDouble();
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
        IconButton(
          tooltip: 'Rewind 10 seconds',
          iconSize: 28,
          onPressed: () => ref
              .read(audioEngineProvider.notifier)
              .seekRelative(const Duration(seconds: -10)),
          icon: const Icon(Icons.replay_10_rounded, color: HiHatColors.trace),
        ),
        IconButton(
          tooltip: 'Previous',
          iconSize: 34,
          onPressed: ref.read(audioEngineProvider.notifier).previous,
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
        ),
        const SizedBox(width: 6),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: HiHatColors.coral,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            minimumSize: const Size.square(64),
          ),
          onPressed: ref.read(audioEngineProvider.notifier).toggle,
          child: Icon(
            state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 36,
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Next',
          iconSize: 34,
          onPressed: ref.read(audioEngineProvider.notifier).next,
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
        ),
        IconButton(
          tooltip: 'Forward 10 seconds',
          iconSize: 28,
          onPressed: () => ref
              .read(audioEngineProvider.notifier)
              .seekRelative(const Duration(seconds: 10)),
          icon: const Icon(Icons.forward_10_rounded, color: HiHatColors.trace),
        ),
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

class _Volume extends ConsumerWidget {
  const _Volume({required this.state});
  final PlaybackState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    label: 'Volume ${(state.volume * 100).round()} percent',
    child: Column(
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
        Row(
          children: [
            IconButton(
              tooltip: state.muted ? 'Unmute' : 'Mute',
              onPressed: ref.read(audioEngineProvider.notifier).toggleMute,
              icon: Icon(
                state.muted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
              ),
            ),
            Expanded(
              child: Slider(
                value: state.volume,
                onChanged: ref.read(audioEngineProvider.notifier).setVolume,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key, this.scrollable = false});

  final bool scrollable;

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final scrollController = SmoothScrollController(debugLabel: 'lyrics');

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(audioEngineProvider);
    final track = playback.track;
    if (track == null) return const SizedBox.shrink();
    final showEnglish = ref.watch(
      _showEnglishLyricsProvider(track.providerTrackId),
    );
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
                data: (translation) => translation == null
                    ? const Text('These lyrics are already in English.')
                    : Column(
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
                      ),
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
                    return SelectableText(
                      lyrics.plain,
                      style: const TextStyle(height: 1.65),
                    );
                  }
                  var active = -1;
                  for (var i = 0; i < lyrics.synced.length; i++) {
                    if (lyrics.synced[i].time <= playback.position) active = i;
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < lyrics.synced.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            lyrics.synced[i].text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: i == active ? 19 : 16,
                              fontWeight: i == active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: i == active
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Lyrics provided by LRCLIB',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                },
              );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = Text(
              'Lyrics',
              style: Theme.of(context).textTheme.titleLarge,
            );
            final languageSelector = SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Original')),
                ButtonSegment(value: true, label: Text('English')),
              ],
              selected: {showEnglish},
              onSelectionChanged: (selection) =>
                  ref
                          .read(
                            _showEnglishLyricsProvider(track.providerTrackId)
                                .notifier,
                          )
                          .state =
                      selection.first,
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
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 12),
          child: lyricsContent,
        ),
      ],
    );
    if (!widget.scrollable) return content;
    return SingleChildScrollView(
      controller: scrollController,
      primary: false,
      child: content,
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
    return SafeArea(
      child: Column(
        children: [
          ListTile(
            title: const Text('Playback queue'),
            subtitle: Text(
              state.relatedAutoplay
                  ? '${state.queue.length} songs · Unlimited related queue on'
                  : '${state.queue.length} songs · Unlimited queue off',
            ),
            trailing: TextButton(
              onPressed: state.queue.isEmpty
                  ? null
                  : ref.read(audioEngineProvider.notifier).clearQueue,
              child: const Text('Clear'),
            ),
          ),
          if (state.queue.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Your queue is empty. Add songs from Home, Search, Albums, Library, or playlists.',
                ),
              ),
            )
          else
            Expanded(
              child: ReorderableListView.builder(
                itemCount: state.queue.length,
                onReorderItem: ref
                    .read(audioEngineProvider.notifier)
                    .reorderQueue,
                itemBuilder: (context, i) {
                  final t = state.queue[i];
                  return ListTile(
                    key: ValueKey('$i:${t.id}'),
                    selected: i == state.currentIndex,
                    leading: i == state.currentIndex
                        ? const Icon(Icons.graphic_eq)
                        : Text('${i + 1}'),
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
