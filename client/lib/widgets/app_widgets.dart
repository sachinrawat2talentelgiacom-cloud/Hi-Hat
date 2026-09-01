import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/download_service.dart';
import '../services/track_playback_coordinator.dart';
import '../features/player/song_actions.dart';
import 'track_artwork.dart';

/// Hi Hat's compact soundwave brand mark.
class SoundwaveLogo extends StatelessWidget {
  const SoundwaveLogo({
    super.key,
    this.title = 'Hi Hat',
    this.fontSize = 20,
    this.iconHeight = 22,
  });

  final String title;
  final double fontSize;
  final double iconHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: iconHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildBar(0.45),
              const SizedBox(width: 2.5),
              _buildBar(0.8),
              const SizedBox(width: 2.5),
              _buildBar(1.0),
              const SizedBox(width: 2.5),
              _buildBar(0.65),
              const SizedBox(width: 2.5),
              _buildBar(0.35),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double heightFactor) {
    return Container(
      width: 3.5,
      height: iconHeight * heightFactor,
      decoration: BoxDecoration(
        color: HiHatColors.coral,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Explicit badge widget '[E]'
class ExplicitBadge extends StatelessWidget {
  const ExplicitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFF2E313D),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'E',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFFD2D5E0),
          height: 1.0,
        ),
      ),
    );
  }
}

/// Hero Banner for Albums, Discovery Mix, Featured & Playlists
class HeroBanner extends ConsumerWidget {
  const HeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.artworkUrl,
    this.songCountText,
    this.durationText,
    this.qualityBadge,
    this.onPlayAll,
    this.onShuffle,
    this.onReload,
    this.onEdit,
    this.onMore,
    this.isPlaying = false,
  });

  final String title;
  final String subtitle;
  final String? artworkUrl;
  final String? songCountText;
  final String? durationText;
  final String? qualityBadge;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffle;
  final VoidCallback? onReload;
  final VoidCallback? onEdit;
  final VoidCallback? onMore;
  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 720;
    final isPhone = width < 520;
    final artSize = isPhone ? 112.0 : (isCompact ? 130.0 : 200.0);

    final artwork = TrackArtwork(
      artworkUrl: artworkUrl,
      width: artSize,
      height: artSize,
      highRes: true,
      borderRadius: BorderRadius.circular(isPhone ? 12 : 16),
      iconSize: isPhone ? 48 : 64,
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: isPhone ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isPhone ? 20 : (isCompact ? 22 : 32),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Colors.white,
                ),
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: HiHatColors.trace,
                tooltip: 'Edit details / preferences',
                onPressed: onEdit,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: isPhone ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: HiHatColors.trace,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (songCountText != null)
              _HeroMetadata(
                icon: Icons.play_circle_outline_rounded,
                label: songCountText!,
              ),
            if (durationText != null)
              _HeroMetadata(
                icon: Icons.access_time_rounded,
                label: durationText!,
              ),
            if (qualityBadge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: HiHatColors.coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: HiHatColors.coral.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  qualityBadge!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: HiHatColors.coral,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (onPlayAll != null)
              FilledButton.icon(
                onPressed: onPlayAll,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 20,
                ),
                label: Text(isPlaying ? 'Pause' : 'Play all'),
              ),
            if (onShuffle != null)
              OutlinedButton.icon(
                onPressed: onShuffle,
                icon: const Icon(Icons.shuffle_rounded, size: 18),
                label: const Text('Shuffle'),
              ),
            if (onReload != null)
              OutlinedButton.icon(
                onPressed: onReload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reload feed'),
              ),
            if (onMore != null)
              TextButton.icon(
                onPressed: onMore,
                icon: const Icon(Icons.more_horiz_rounded, size: 18),
                label: const Text('More'),
              ),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.surfaceContainer,
        border: Border.all(color: colors.outlineVariant, width: 1),
      ),
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isPhone)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: artwork),
                const SizedBox(height: 18),
                details,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                artwork,
                SizedBox(width: isCompact ? 16 : 28),
                Expanded(child: details),
                // Giant Coral Circular Play Button on right (Desktop)
                if (!isCompact && onPlayAll != null) ...[
                  const SizedBox(width: 20),
                  Material(
                    color: HiHatColors.coral,
                    shape: const CircleBorder(),
                    elevation: 6,
                    shadowColor: HiHatColors.coral.withValues(alpha: 0.4),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onPlayAll,
                      child: Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroMetadata extends StatelessWidget {
  const _HeroMetadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: HiHatColors.trace),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: HiHatColors.trace,
            fontWeight: FontWeight.w500,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}

/// Table column header for track lists
class TrackTableHeader extends StatelessWidget {
  const TrackTableHeader({
    super.key,
    this.secondaryColumnTitle = 'Plays',
    this.onMore,
  });

  final String secondaryColumnTitle;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showPlays = width >= 640;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 58), // Match artwork width (44) + spacing (14)
          const Expanded(
            flex: 5,
            child: Text(
              'Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HiHatColors.trace,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (showPlays)
            Expanded(
              flex: 3,
              child: Text(
                secondaryColumnTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HiHatColors.trace,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          const SizedBox(
            width: 54,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.access_time_rounded,
                size: 15,
                color: HiHatColors.trace,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single Track Row matching reference screenshot table item style
class TrackTableRow extends ConsumerStatefulWidget {
  const TrackTableRow({
    super.key,
    required this.track,
    this.secondaryText,
    this.playlistId,
    this.playlistIndex,
    this.onTap,
  });

  final TrackSummary track;
  final String? secondaryText;
  final String? playlistId;
  final int? playlistIndex;
  final VoidCallback? onTap;

  static String formatPlays(int index, int seed) {
    final base = (31552929 + (seed.abs() % 100000000) * (index + 1) * 7);
    final str = base.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  ConsumerState<TrackTableRow> createState() => _TrackTableRowState();
}

class _TrackTableRowState extends ConsumerState<TrackTableRow> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(audioEngineProvider);
    final transfer = ref
        .watch(downloadServiceProvider)
        .forTrack(widget.track.id);
    final isAcquiring = transfer?.isActive ?? false;
    final isCurrent = playback.track?.id == widget.track.id;
    final width = MediaQuery.sizeOf(context).width;
    final showPlays = width >= 640;

    // Derived secondary column text (Plays, Album, or Quality)
    final secondary =
        widget.secondaryText ??
        (widget.track.album != null && widget.track.album!.isNotEmpty
            ? widget.track.album!
            : widget.track.quality.display);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Material(
        color: isHovered
            ? const Color(0xFF1B1D26)
            : isCurrent
            ? const Color(0xFF171922)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onSecondaryTapUp: (details) =>
              _showContextMenu(context, details.globalPosition),
          onLongPress: () => _showContextMenu(context, null),
          onTap: isAcquiring
              ? () => ref
                    .read(downloadServiceProvider.notifier)
                    .focus(widget.track.id)
              : widget.onTap ?? () => _play(context, ref, widget.track),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Thumbnail Artwork
                TrackArtwork(
                  artworkUrl: widget.track.artworkUrl,
                  size: 44,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 14),
                // Title + Artist + Explicit Badge
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.track.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: isCurrent
                                    ? HiHatColors.coral
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (widget.track.explicit) ...[
                            const ExplicitBadge(),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              widget.track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: HiHatColors.trace,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Secondary column (Plays / Album / Quality)
                if (showPlays)
                  Expanded(
                    flex: 3,
                    child: Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: HiHatColors.trace,
                      ),
                    ),
                  ),
                // Duration / Download progress
                SizedBox(
                  width: 54,
                  child: isAcquiring
                      ? Center(
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              value: transfer!.progress > 0
                                  ? transfer.progress
                                  : null,
                              strokeWidth: 2,
                              color: HiHatColors.coral,
                            ),
                          ),
                        )
                      : Text(
                          widget.track.formattedDuration,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCurrent
                                ? HiHatColors.coral
                                : HiHatColors.trace,
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset? position) {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final targetPosition =
        position ??
        (context.findRenderObject() as RenderBox?)?.localToGlobal(
          Offset.zero,
        ) ??
        Offset.zero;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        targetPosition & const Size(40, 40),
        Offset.zero & (overlay?.size ?? const Size(1920, 1080)),
      ),
      items: [
        PopupMenuItem<void>(
          onTap: () =>
              ref.read(audioEngineProvider.notifier).addToQueue(widget.track),
          child: const ListTile(
            dense: true,
            leading: Icon(Icons.queue_music_rounded, size: 18),
            title: Text('Add to queue'),
          ),
        ),
        PopupMenuItem<void>(
          onTap: () => showAddToPlaylist(context, ref, widget.track),
          child: const ListTile(
            dense: true,
            leading: Icon(Icons.playlist_add_rounded, size: 18),
            title: Text('Add to playlist'),
          ),
        ),
      ],
    );
  }

  static Future<void> _play(
    BuildContext context,
    WidgetRef ref,
    TrackSummary track,
  ) async {
    if (track.isLocal) {
      await ref.read(audioEngineProvider.notifier).playLocal(track);
    } else {
      await ref
          .read(trackPlaybackCoordinatorProvider)
          .play(track, Navigator.of(context));
    }
  }
}

/// Large Cover Art Card Block for Home discovery songs
class TrackCardBlock extends ConsumerStatefulWidget {
  const TrackCardBlock({super.key, required this.track, required this.onTap});

  final TrackSummary track;
  final VoidCallback onTap;

  @override
  ConsumerState<TrackCardBlock> createState() => _TrackCardBlockState();
}

class _TrackCardBlockState extends ConsumerState<TrackCardBlock> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(audioEngineProvider);
    final isCurrent = playback.track?.id == widget.track.id;
    final isPlaying = isCurrent && playback.playing;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) =>
            _showContextMenu(context, details.globalPosition),
        onLongPress: () {
          final box = context.findRenderObject() as RenderBox?;
          final pos = box != null
              ? box.localToGlobal(box.size.center(Offset.zero))
              : const Offset(200, 200);
          _showContextMenu(context, pos);
        },
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _isHovered
                ? const Color(0xFF1B1D28)
                : const Color(0xFF13151D),
            border: Border.all(
              color: isCurrent
                  ? HiHatColors.coral.withValues(alpha: 0.8)
                  : (_isHovered
                        ? const Color(0xFF2E3244)
                        : const Color(0xFF1E202B)),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Cover Artwork with overlay play button
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TrackArtwork(
                        artworkUrl:
                            widget.track.highResArtworkUrl ??
                            widget.track.artworkUrl,
                        borderRadius: BorderRadius.circular(12),
                        iconSize: 48,
                      ),
                      // Floating play button on hover or when currently playing
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: AnimatedSlide(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 120),
                          curve: Curves.easeOutCubic,
                          offset: reduceMotion || _isHovered || isPlaying
                              ? Offset.zero
                              : const Offset(0, .25),
                          child: AnimatedOpacity(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 120),
                            curve: Curves.easeOutCubic,
                            opacity: (_isHovered || isPlaying) ? 1.0 : 0.0,
                            child: Material(
                              color: HiHatColors.coral,
                              shape: const CircleBorder(),
                              elevation: 0,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: widget.onTap,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Song Title
              Text(
                widget.track.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? HiHatColors.coral : Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              // Artist and Explicit badge
              Row(
                children: [
                  if (widget.track.explicit == true) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: HiHatColors.trace.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'E',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      widget.track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: HiHatColors.trace,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset? position) {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final targetPosition =
        position ??
        (context.findRenderObject() as RenderBox?)?.localToGlobal(
          Offset.zero,
        ) ??
        Offset.zero;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        targetPosition & const Size(40, 40),
        Offset.zero & (overlay?.size ?? const Size(1920, 1080)),
      ),
      items: [
        PopupMenuItem<void>(
          onTap: () =>
              ref.read(audioEngineProvider.notifier).addToQueue(widget.track),
          child: const ListTile(
            dense: true,
            leading: Icon(Icons.queue_music_rounded, size: 18),
            title: Text('Add to queue'),
          ),
        ),
        PopupMenuItem<void>(
          onTap: () => showAddToPlaylist(context, ref, widget.track),
          child: const ListTile(
            dense: true,
            leading: Icon(Icons.playlist_add_rounded, size: 18),
            title: Text('Add to playlist'),
          ),
        ),
      ],
    );
  }
}
