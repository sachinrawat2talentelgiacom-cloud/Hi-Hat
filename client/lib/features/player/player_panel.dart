import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../services/audio_engine.dart';
import '../../services/download_service.dart';
import '../../widgets/track_artwork.dart';

class PlayerPanel extends ConsumerWidget {
  const PlayerPanel({super.key, this.track});
  final TrackSummary? track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioEngineProvider);
    final current = playback.track ?? track;
    final transfer = current != null
        ? ref.watch(downloadServiceProvider).forTrack(current.id)
        : null;
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: TrackArtwork(
                      artworkUrl: current.highResArtworkUrl ?? current.artworkUrl,
                      borderRadius: BorderRadius.circular(14),
                      iconSize: 72,
                      highRes: true,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (current.explicit) ...[
                      const _ExplicitBadge(),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        current.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  current.artist,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (current.album != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    current.albumWithYear ?? current.album!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
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
                const SizedBox(height: 14),
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
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 18),
                _Reading(
                  label: current.isLocal ? 'VERIFIED SOURCE' : 'LISTED QUALITY',
                  value: current.quality.display,
                  icon: current.isLocal
                      ? Icons.verified_outlined
                      : Icons.high_quality_outlined,
                ),
                const SizedBox(height: 12),
                _Reading(
                  label: 'OUTPUT',
                  value: playback.outputLabel,
                  icon: Icons.speaker_outlined,
                ),
                if (current.quality.channelsDisplay != null ||
                    current.quality.bitrateDisplay != null) ...[
                  const SizedBox(height: 12),
                  _Reading(
                    label: 'AUDIO STREAM',
                    value: [
                      current.quality.codec ?? 'FLAC',
                      if (current.quality.channelsDisplay != null)
                        current.quality.channelsDisplay!,
                      if (current.quality.bitrateDisplay != null)
                        current.quality.bitrateDisplay!,
                    ].join(' · '),
                    icon: Icons.graphic_eq_outlined,
                  ),
                ],
                if (current.musicalKeyDisplay != null || current.tempoDisplay != null) ...[
                  const SizedBox(height: 12),
                  _Reading(
                    label: 'ACOUSTIC PROPERTIES',
                    value: [
                      if (current.musicalKeyDisplay != null)
                        'Key: ${current.musicalKeyDisplay}',
                      if (current.tempoDisplay != null)
                        'Tempo: ${current.tempoDisplay}',
                    ].join('  ·  '),
                    icon: Icons.music_note_outlined,
                  ),
                ],
                if (current.replayGain != null || current.peak != null) ...[
                  const SizedBox(height: 12),
                  _Reading(
                    label: 'LEVELS & GAIN',
                    value: [
                      if (current.replayGain != null)
                        'Gain: ${current.replayGain! > 0 ? '+' : ''}${current.replayGain!.toStringAsFixed(1)} dB',
                      if (current.peak != null)
                        'Peak: ${(current.peak! * 100).toStringAsFixed(1)}%',
                    ].join('  ·  '),
                    icon: Icons.tune_outlined,
                  ),
                ],
                if (current.formattedTrackNumber != null || current.genre != null) ...[
                  const SizedBox(height: 12),
                  _Reading(
                    label: 'CATALOG INFO',
                    value: [
                      if (current.formattedTrackNumber != null)
                        current.formattedTrackNumber!,
                      if (current.genre != null && current.genre!.isNotEmpty)
                        current.genre!,
                    ].join('  ·  '),
                    icon: Icons.tag_outlined,
                  ),
                ],
                if (current.isrc != null && current.isrc!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Reading(
                    label: 'ISRC IDENTIFIER',
                    value: current.isrc!,
                    icon: Icons.fingerprint_outlined,
                  ),
                ],
                if (current.copyright != null && current.copyright!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Reading(
                    label: 'COPYRIGHT / RELEASE',
                    value: current.copyright!,
                    icon: Icons.copyright_outlined,
                  ),
                ],
                if (current.isLocal && current.formattedFileSize != null) ...[
                  const SizedBox(height: 12),
                  _Reading(
                    label: 'LOCAL ARCHIVE',
                    value: [
                      current.formattedFileSize!,
                      'FLAC lossless',
                    ].join('  ·  '),
                    icon: Icons.inventory_2_outlined,
                  ),
                ],
                if (transfer != null &&
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
                ] else if (transfer != null &&
                    transfer.phase == 'FAILED') ...[
                  const SizedBox(height: 22),
                  _Reading(
                    label: 'SOURCE UNAVAILABLE',
                    value: transfer.error ??
                        'This track could not be downloaded. Try another result.',
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
    final track = playback.track;
    final transfer = track != null
        ? ref.watch(downloadServiceProvider).forTrack(track.id)
        : null;
    if (track == null) return const SizedBox.shrink();
    final acquiring =
        transfer != null &&
        PlayerPanel._isActivePhase(transfer.phase);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SizedBox(
        height: 72,
        child: Stack(
          children: [
            Row(
              children: [
                const SizedBox(width: 14),
                TrackArtwork(
                  artworkUrl: track.artworkUrl,
                  size: 46,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (track.explicit) ...[
                            const _ExplicitBadge(),
                            const SizedBox(width: 5),
                          ],
                          Expanded(
                            child: Text(
                              track.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        acquiring
                            ? '${PlayerPanel._phase(transfer.phase)} ${PlayerPanel._percent(transfer.progress)}'
                            : '${track.artist}${track.album != null ? ' · ${track.album}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: playback.playing ? 'Pause' : 'Play',
                  onPressed: track.isLocal
                      ? () => ref.read(audioEngineProvider.notifier).toggle()
                      : null,
                  icon: Icon(
                    playback.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 32,
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

class _ExplicitBadge extends StatelessWidget {
  const _ExplicitBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'E',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.1,
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
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
