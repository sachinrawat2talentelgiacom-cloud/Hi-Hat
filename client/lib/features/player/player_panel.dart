import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../services/audio_engine.dart';
import '../../services/download_service.dart';

class PlayerPanel extends ConsumerWidget {
  const PlayerPanel({super.key, this.track});
  final TrackSummary? track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioEngineProvider);
    final transfer = ref.watch(downloadServiceProvider);
    final current = playback.track ?? track;
    if (current == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(38),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spatial_audio_off_outlined, size: 48),
              SizedBox(height: 18),
              Text('The chamber is quiet'),
              SizedBox(height: 8),
              Text(
                'Choose a local track or start a search.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final totalMs = playback.duration.inMilliseconds;
    final progress = totalMs > 0
        ? (playback.position.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                _LargeArtwork(track: current),
                const SizedBox(height: 26),
                Text(
                  current.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  current.artist,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Slider(
                  value: progress,
                  onChanged: playback.duration == Duration.zero
                      ? null
                      : (value) => ref
                            .read(audioEngineProvider.notifier)
                            .seek(playback.duration * value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_time(playback.position)),
                    Text(_time(playback.duration)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: null,
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 36,
                    ),
                    const SizedBox(width: 20),
                    FilledButton(
                      onPressed: current.isLocal
                          ? () =>
                                ref.read(audioEngineProvider.notifier).toggle()
                          : null,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        minimumSize: const Size.square(72),
                      ),
                      child: Icon(
                        playback.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: null,
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 36,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 18),
                _Reading(
                  label: current.isLocal ? 'VERIFIED SOURCE' : 'LISTED QUALITY',
                  value: current.quality.display,
                  icon: current.isLocal
                      ? Icons.verified_outlined
                      : Icons.high_quality_outlined,
                ),
                const SizedBox(height: 14),
                _Reading(
                  label: 'OUTPUT',
                  value: playback.outputLabel,
                  icon: Icons.speaker_outlined,
                ),
                if (transfer.trackId == current.id &&
                    _isActivePhase(transfer.phase)) ...[
                  const SizedBox(height: 22),
                  LinearProgressIndicator(
                    value: transfer.progress > 0 ? transfer.progress : null,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      transfer.progress > 0
                          ? '${_phase(transfer.phase)}  ${_percent(transfer.progress)}'
                          : _phase(transfer.phase),
                    ),
                  ),
                ] else if (transfer.trackId == current.id &&
                    transfer.phase == 'FAILED') ...[
                  const SizedBox(height: 22),
                  _Reading(
                    label: 'SOURCE UNAVAILABLE',
                    value: transfer.error ?? 'This track could not be downloaded. Try another result.',
                    icon: Icons.block_outlined,
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _time(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String _percent(double value) => '${(value * 100).round()}%';

  static String _phase(String? value) => switch (value) {
    'RESOLVING' => 'Resolving the highest lossless source…',
    'OPENING_PROVIDER' => 'Opening the provider in the background…',
    'AUTH_REQUIRED' => 'Provider verification required…',
    'MATCHING_TRACK' => 'Matching the exact track…',
    'STARTING_DOWNLOAD' => 'Starting lossless preparation…',
    'PREPARING_AUDIO' => 'Preparing lossless audio…',
    'DOWNLOADING' => 'Downloading FLAC locally…',
    'VERIFYING' => 'Verifying the FLAC…',
    'FINALIZING' => 'Saving to your library…',
    _ => 'Preparing…',
  };

  static bool _isActivePhase(String? value) => const {
    'OPENING_PROVIDER',
    'AUTH_REQUIRED',
    'MATCHING_TRACK',
    'STARTING_DOWNLOAD',
    'PREPARING_AUDIO',
    'DOWNLOADING',
    'VERIFYING',
    'FINALIZING',
  }.contains(value);
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioEngineProvider);
    final transfer = ref.watch(downloadServiceProvider);
    final track = playback.track;
    if (track == null) return const SizedBox.shrink();
    final acquiring =
        transfer.trackId == track.id &&
        PlayerPanel._isActivePhase(transfer.phase);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SizedBox(
        height: 72,
        child: Stack(
          children: [
            Row(
              children: [
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        acquiring
                            ? '${PlayerPanel._phase(transfer.phase)} ${PlayerPanel._percent(transfer.progress)}'
                            : track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: playback.playing ? 'Pause' : 'Play',
                  onPressed: track.isLocal
                      ? () => ref.read(audioEngineProvider.notifier).toggle()
                      : null,
                  icon: Icon(
                    playback.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            if (acquiring)
              Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  value: transfer.progress > 0 ? transfer.progress : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LargeArtwork extends StatelessWidget {
  const _LargeArtwork({required this.track});
  final TrackSummary track;
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: track.artworkUrl == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: const Icon(Icons.album, size: 90),
              )
            : Image.network(
                track.artworkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Icon(Icons.album, size: 90),
                ),
              ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    ],
  );
}
