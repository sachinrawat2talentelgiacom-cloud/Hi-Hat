import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../core/theme.dart';
import '../../core/scroll_behavior.dart';
import '../../services/audio_engine.dart';
import '../../services/download_service.dart';
import '../../widgets/track_artwork.dart';
import 'full_player_screen.dart';

class PlayerPanel extends ConsumerStatefulWidget {
  const PlayerPanel({super.key, this.track});
  final TrackSummary? track;

  @override
  ConsumerState<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends ConsumerState<PlayerPanel> {
  final scrollController = SmoothScrollController(debugLabel: 'player-panel');

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(audioEngineProvider);
    final current = playback.track ?? widget.track;
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
              Icon(Icons.spatial_audio_off_rounded, size: 48),
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
    return _ReferenceSidePlayer(
      playback: playback,
      track: current,
      transfer: transfer,
      scrollController: scrollController,
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

class _ReferenceSidePlayer extends ConsumerWidget {
  const _ReferenceSidePlayer({
    required this.playback,
    required this.track,
    required this.transfer,
    required this.scrollController,
  });

  final PlaybackState playback;
  final TrackSummary track;
  final TransferState? transfer;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ColoredBox(
    color: const Color(0xFF080B09),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 400 ? 16.0 : 12.0;
        final artworkSize = math.min(
          408.0,
          constraints.maxWidth - (horizontal * 2),
        );
        final activeTransfer =
            transfer != null &&
            _PlayerPanelState._isActivePhase(transfer!.phase);
        return SingleChildScrollView(
          controller: scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: const ValueKey('side-player-header'),
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Open full-screen player',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const FullPlayerScreen(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.open_in_full_rounded,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Queue',
                          onPressed: () => showQueue(context),
                          icon: const Icon(Icons.queue_music_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox.square(
                      key: const ValueKey('side-player-artwork'),
                      dimension: artworkSize,
                      child: TrackArtwork(
                        artworkUrl: track.highResArtworkUrl ?? track.artworkUrl,
                        borderRadius: BorderRadius.circular(14),
                        iconSize: 72,
                        highRes: true,
                        showBorder: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (track.explicit) ...[
                        const _ExplicitBadge(),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          track.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF858C86),
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _SidePlayerProgress(playback: playback),
                  const SizedBox(height: 20),
                  _SidePlayerTransport(playback: playback),
                  const SizedBox(height: 23),
                  _SidePlayerSecondaryControls(playback: playback),
                  const SizedBox(height: 23),
                  _SidePlayerMetadata(track: track),
                  if (activeTransfer) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: transfer!.progress > 0 ? transfer!.progress : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      transfer!.progress > 0
                          ? '${_PlayerPanelState._phase(transfer!.phase)} ${_PlayerPanelState._percent(transfer!.progress)}'
                          : _PlayerPanelState._phase(transfer!.phase),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 23),
                  Container(
                    key: const ValueKey('side-player-lyrics-card'),
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D110F),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1A211C)),
                    ),
                    child: const LyricsView(
                      scrollable: false,
                      compactPanel: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _SidePlayerProgress extends ConsumerWidget {
  const _SidePlayerProgress({required this.playback});

  final PlaybackState playback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final max = playback.duration.inMilliseconds.toDouble();
    final value = max <= 0
        ? 0.0
        : playback.position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    return SizedBox(
      key: const ValueKey('side-player-progress'),
      height: 40,
      child: Column(
        children: [
          SizedBox(
            height: 20,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: HiHatColors.signal,
                inactiveTrackColor: const Color(0xFF242925),
                trackHeight: 3,
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
              Text(_PlayerPanelState._time(playback.position)),
              Text(_PlayerPanelState._time(playback.duration)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidePlayerTransport extends ConsumerWidget {
  const _SidePlayerTransport({required this.playback});

  final PlaybackState playback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(audioEngineProvider.notifier);
    return SizedBox(
      key: const ValueKey('side-player-transport'),
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SideTransportButton(
            tooltip: 'Rewind 10 seconds',
            icon: Icons.replay_10_rounded,
            onPressed: () => engine.seekRelative(const Duration(seconds: -10)),
          ),
          _SideTransportButton(
            tooltip: 'Previous',
            icon: Icons.skip_previous_rounded,
            onPressed: engine.previous,
          ),
          SizedBox.square(
            dimension: 56,
            child: IconButton(
              tooltip: playback.playing ? 'Pause' : 'Play',
              onPressed: trackCanPlay(playback) ? engine.toggle : null,
              icon: Icon(
                playback.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          _SideTransportButton(
            tooltip: 'Next',
            icon: Icons.skip_next_rounded,
            onPressed: engine.next,
          ),
          _SideTransportButton(
            tooltip: 'Forward 10 seconds',
            icon: Icons.forward_10_rounded,
            onPressed: () => engine.seekRelative(const Duration(seconds: 10)),
          ),
        ],
      ),
    );
  }

  bool trackCanPlay(PlaybackState state) => state.track?.isLocal ?? false;
}

class _SideTransportButton extends StatelessWidget {
  const _SideTransportButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 48,
    child: IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, color: HiHatColors.mineral, size: 22),
    ),
  );
}

class _SidePlayerSecondaryControls extends ConsumerWidget {
  const _SidePlayerSecondaryControls({required this.playback});

  final PlaybackState playback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(audioEngineProvider.notifier);
    return SizedBox(
      key: const ValueKey('side-player-secondary-controls'),
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Repeat ${playback.repeatMode.name}',
            onPressed: engine.cycleRepeat,
            icon: Icon(
              playback.repeatMode == PlaybackRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              size: 20,
              color: playback.repeatMode == PlaybackRepeatMode.off
                  ? HiHatColors.trace
                  : Colors.white,
            ),
          ),
          IconButton(
            tooltip: playback.shuffle ? 'Turn shuffle off' : 'Turn shuffle on',
            onPressed: engine.toggleShuffle,
            icon: Icon(
              Icons.shuffle_rounded,
              size: 20,
              color: playback.shuffle ? Colors.white : HiHatColors.trace,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: playback.muted ? 'Unmute' : 'Mute',
            onPressed: engine.toggleMute,
            icon: Icon(
              playback.muted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              size: 20,
              color: HiHatColors.trace,
            ),
          ),
          SizedBox(
            width: 160,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: HiHatColors.trace,
                inactiveTrackColor: const Color(0xFF242925),
                trackHeight: 4,
                thumbShape: SliderComponentShape.noThumb,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: playback.volume,
                onChanged: engine.setVolume,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePlayerMetadata extends StatelessWidget {
  const _SidePlayerMetadata({required this.track});

  final TrackSummary track;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('side-player-metadata'),
    height: 151,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0D110F),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF1A211C)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Expanded(
              child: _SideMetadataValue(
                label: 'SOURCE',
                value: track.quality.display,
                icon: Icons.shuffle_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SideMetadataValue(
                label: 'LOCAL ARCHIVE',
                value: track.isLocal
                    ? [
                        if (track.formattedFileSize != null)
                          track.formattedFileSize!,
                        'FLAC Lossless',
                      ].join('  \u00B7  ')
                    : 'Not archived',
                icon: Icons.inventory_2_rounded,
              ),
            ),
          ],
        ),
        _SideMetadataValue(
          label: 'OWNED FILE',
          value: track.localPath ?? 'Not stored on this device yet',
          icon: Icons.folder_rounded,
        ),
      ],
    ),
  );
}

class _SideMetadataValue extends StatelessWidget {
  const _SideMetadataValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF727A73)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF727A73),
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFD8DED8),
          fontFamily: 'Inter',
          fontSize: 14,
          height: 1.2,
        ),
      ),
    ],
  );
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
        transfer != null && _PlayerPanelState._isActivePhase(transfer.phase);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 680;
    final totalMs = playback.duration.inMilliseconds;
    final progress = totalMs > 0
        ? (playback.position.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;

    if (!isDesktop) {
      return Material(
        color: HiHatColors.chamberRaised,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FullPlayerScreen()),
          ),
          child: SizedBox(
            height: 72,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(
                    value: acquiring ? transfer.progress : progress,
                    minHeight: 2,
                    backgroundColor: HiHatColors.trace.withValues(alpha: .18),
                    color: acquiring ? HiHatColors.cue : HiHatColors.signal,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                  child: Row(
                    children: [
                      TrackArtwork(
                        artworkUrl: track.artworkUrl,
                        size: 48,
                        borderRadius: BorderRadius.circular(8),
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
                                color: HiHatColors.mineral,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              acquiring
                                  ? '${_PlayerPanelState._phase(transfer.phase)} ${_PlayerPanelState._percent(transfer.progress)}'
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
                      IconButton.filled(
                        tooltip: playback.playing ? 'Pause' : 'Play',
                        onPressed: track.isLocal
                            ? () => ref
                                  .read(audioEngineProvider.notifier)
                                  .toggle()
                            : null,
                        style: IconButton.styleFrom(
                          backgroundColor: HiHatColors.signal,
                          foregroundColor: HiHatColors.onSignal,
                        ),
                        icon: Icon(
                          playback.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 25,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next',
                        onPressed: ref.read(audioEngineProvider.notifier).next,
                        icon: const Icon(
                          Icons.skip_next_rounded,
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
                                ? '${_PlayerPanelState._phase(transfer.phase)} ${_PlayerPanelState._percent(transfer.progress)}'
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
                          _PlayerPanelState._time(playback.position),
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
                          _PlayerPanelState._time(playback.duration),
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
