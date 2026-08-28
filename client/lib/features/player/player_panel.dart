import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../core/theme.dart';
import '../../services/audio_engine.dart';
import '../../services/download_service.dart';
import '../../widgets/track_artwork.dart';
import '../../widgets/brand_widgets.dart';
import 'full_player_screen.dart';
import 'song_actions.dart';

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
                Row(
                  children: [
                    const HiHatEyebrow('Listening instrument'),
                    const Spacer(),
                    if (current.isLocal)
                      const HiHatStatusChip(
                        label: 'Owned file',
                        icon: Icons.offline_pin_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 360,
                    maxHeight: 360,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: TrackArtwork(
                      artworkUrl:
                          current.highResArtworkUrl ?? current.artworkUrl,
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
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
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
                      tooltip: playback.shuffle ? 'Shuffle on' : 'Shuffle off',
                      isSelected: playback.shuffle,
                      onPressed: ref
                          .read(audioEngineProvider.notifier)
                          .toggleShuffle,
                      icon: const Icon(Icons.shuffle),
                    ),
                    IconButton(
                      tooltip: 'Previous',
                      onPressed: ref
                          .read(audioEngineProvider.notifier)
                          .previous,
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 36,
                    ),
                    const SizedBox(width: 4),
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
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Next',
                      onPressed: ref.read(audioEngineProvider.notifier).next,
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 36,
                    ),
                    IconButton(
                      tooltip: 'Repeat ${playback.repeatMode.name}',
                      isSelected: playback.repeatMode != PlaybackRepeatMode.off,
                      onPressed: ref
                          .read(audioEngineProvider.notifier)
                          .cycleRepeat,
                      icon: Icon(
                        playback.repeatMode == PlaybackRepeatMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: playback.muted ? 'Unmute' : 'Mute',
                      onPressed: ref
                          .read(audioEngineProvider.notifier)
                          .toggleMute,
                      icon: Icon(
                        playback.muted ? Icons.volume_off : Icons.volume_up,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: playback.volume,
                        onChanged: ref
                            .read(audioEngineProvider.notifier)
                            .setVolume,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Queue',
                      onPressed: () => showQueue(context),
                      icon: const Icon(Icons.queue_music),
                    ),
                    IconButton(
                      tooltip: 'Open full-screen player',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const FullPlayerScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_full),
                    ),
                    SongActionsButton(track: current),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 18),
                _Reading(
                  label: current.isLocal ? 'SOURCE' : 'LISTED QUALITY',
                  value: current.quality.display,
                  icon: current.isLocal
                      ? Icons.verified_outlined
                      : Icons.high_quality_outlined,
                ),
                const SizedBox(height: 12),
                _Reading(
                  label: 'OWNED FILE',
                  value: current.localPath ?? 'Not stored on this device yet',
                  icon: current.isLocal
                      ? Icons.folder_open_outlined
                      : Icons.cloud_download_outlined,
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
                if (current.musicalKeyDisplay != null ||
                    current.tempoDisplay != null) ...[
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
                if (current.formattedTrackNumber != null ||
                    current.genre != null) ...[
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
                if (current.copyright != null &&
                    current.copyright!.isNotEmpty) ...[
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
                if (transfer != null && _isActivePhase(transfer.phase)) ...[
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
                ] else if (transfer != null && transfer.phase == 'FAILED') ...[
                  const SizedBox(height: 22),
                  _Reading(
                    label: 'SOURCE UNAVAILABLE',
                    value: transfer.error ?? 'This track could not be downloaded. Try another result.',
                    icon: Icons.block_outlined,
                  ),
                ],
                const SizedBox(height: 24),
                const LyricsView(),
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
        transfer != null && PlayerPanel._isActivePhase(transfer.phase);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 680;
    final totalMs = playback.duration.inMilliseconds;
    final progress = totalMs > 0
        ? (playback.position.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;

    if (!isDesktop) {
      // Mobile / Compact Mini Player Layout
      return Material(
        color: const Color(0xFF0C0D11),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FullPlayerScreen()),
          ),
          child: Container(
            height: 68,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1E202B), width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                TrackArtwork(
                  artworkUrl: track.artworkUrl,
                  size: 44,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        acquiring
                            ? '${PlayerPanel._phase(transfer.phase)} ${PlayerPanel._percent(transfer.progress)}'
                            : track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: HiHatColors.trace,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: 30,
                  onPressed: track.isLocal
                      ? () => ref.read(audioEngineProvider.notifier).toggle()
                      : null,
                  icon: Icon(
                    playback.playing
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: HiHatColors.coral,
                  ),
                ),
                IconButton(
                  iconSize: 24,
                  onPressed: ref.read(audioEngineProvider.notifier).next,
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    color: HiHatColors.trace,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Desktop 3-Section Layout matching reference screenshot
    return Material(
      color: const Color(0xFF0C0D11),
      child: Container(
        height: 86,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E202B), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Left Section: Artwork + Title + Artist
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FullPlayerScreen(),
                ),
              ),
              child: SizedBox(
                width: 220,
                child: Row(
                  children: [
                    TrackArtwork(
                      artworkUrl: track.artworkUrl,
                      size: 48,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(width: 12),
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: HiHatColors.trace,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center Section: Transport Controls & Timeline Slider
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Transport controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 20,
                          tooltip: 'Replay 10s',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () => ref
                              .read(audioEngineProvider.notifier)
                              .seekRelative(const Duration(seconds: -10)),
                          icon: const Icon(
                            Icons.replay_10_rounded,
                            color: HiHatColors.mineral,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          iconSize: 22,
                          tooltip: 'Previous',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: ref
                              .read(audioEngineProvider.notifier)
                              .previous,
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: HiHatColors.mineral,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Play/Pause button
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: track.isLocal
                                ? () => ref
                                      .read(audioEngineProvider.notifier)
                                      .toggle()
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                playback.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          iconSize: 22,
                          tooltip: 'Next',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: ref
                              .read(audioEngineProvider.notifier)
                              .next,
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: HiHatColors.mineral,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          iconSize: 20,
                          tooltip: 'Forward 10s',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () => ref
                              .read(audioEngineProvider.notifier)
                              .seekRelative(const Duration(seconds: 10)),
                          icon: const Icon(
                            Icons.forward_10_rounded,
                            color: HiHatColors.mineral,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Progress Slider
                    Row(
                      children: [
                        Text(
                          PlayerPanel._time(playback.position),
                          style: const TextStyle(
                            fontSize: 11,
                            color: HiHatColors.trace,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 4.5,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10,
                              ),
                              activeTrackColor: HiHatColors.coral,
                              inactiveTrackColor: const Color(0xFF282A36),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: progress,
                              onChanged: playback.duration == Duration.zero
                                  ? null
                                  : (value) => ref
                                        .read(audioEngineProvider.notifier)
                                        .seek(playback.duration * value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          PlayerPanel._time(playback.duration),
                          style: const TextStyle(
                            fontSize: 11,
                            color: HiHatColors.trace,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Right Section: Lyrics, Volume, Queue, Fullscreen
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lyrics button
                IconButton(
                  iconSize: 19,
                  tooltip: 'Lyrics',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => const FractionallySizedBox(
                      heightFactor: 0.75,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: LyricsView(),
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.notes_rounded,
                    color: HiHatColors.trace,
                  ),
                ),
                const SizedBox(width: 6),
                // Volume Control
                IconButton(
                  iconSize: 20,
                  tooltip: playback.muted ? 'Unmute' : 'Mute',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: ref.read(audioEngineProvider.notifier).toggleMute,
                  icon: Icon(
                    playback.muted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: HiHatColors.trace,
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4.5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 8,
                      ),
                      activeTrackColor: HiHatColors.coral,
                      inactiveTrackColor: const Color(0xFF282A36),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: playback.volume,
                      onChanged: ref
                          .read(audioEngineProvider.notifier)
                          .setVolume,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Queue Button (clean icon matching reference)
                IconButton(
                  iconSize: 20,
                  tooltip: 'Queue (${playback.queue.length})',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => showQueue(context),
                  icon: const Icon(
                    Icons.queue_music_rounded,
                    color: HiHatColors.trace,
                  ),
                ),
                const SizedBox(width: 6),
                // Expand Fullscreen button
                IconButton(
                  iconSize: 18,
                  tooltip: 'Full player',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FullPlayerScreen(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.open_in_full_rounded,
                    color: HiHatColors.trace,
                  ),
                ),
              ],
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
