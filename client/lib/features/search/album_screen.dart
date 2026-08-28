import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/album.dart';
import '../../models/track.dart';
import '../../services/audio_engine.dart';
import '../../services/provider_search_service.dart';
import '../../widgets/app_widgets.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  const AlbumScreen({super.key, required this.album});
  final AlbumSummary album;

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  late final Future<AlbumSummary> details;

  @override
  void initState() {
    super.initState();
    details = ref
        .read(providerSearchServiceProvider)
        .albumDetails(widget.album);
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(audioEngineProvider);
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 700 ? 16.0 : 28.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.title),
        backgroundColor: const Color(0xFF0C0D11),
        elevation: 0,
      ),
      body: FutureBuilder<AlbumSummary>(
        future: details,
        builder: (context, snapshot) {
          final album = snapshot.data ?? widget.album;
          final isPlaying = playback.playing &&
              album.tracks.any((t) => t.id == playback.track?.id);

          return CustomScrollView(
            slivers: [
              // Hero Banner matching screenshot
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
                sliver: SliverToBoxAdapter(
                  child: HeroBanner(
                    title: album.title,
                    subtitle: 'By ${album.artist}',
                    artworkUrl: album.artworkUrl,
                    songCountText: '${album.tracks.length} songs',
                    durationText: album.releaseDate ?? 'FLAC Lossless',
                    qualityBadge: 'FLAC Lossless',
                    isPlaying: isPlaying,
                    onPlayAll: album.tracks.isEmpty
                        ? null
                        : () => _playAll(album.tracks),
                    onShuffle: album.tracks.isEmpty
                        ? null
                        : () {
                            final tracks = [...album.tracks]..shuffle();
                            _playAll(tracks);
                          },
                    onMore: album.tracks.isEmpty
                        ? null
                        : () => ref
                            .read(audioEngineProvider.notifier)
                            .addAllToQueue(album.tracks),
                  ),
                ),
              ),

              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: HiHatColors.coral),
                  ),
                )
              else if (snapshot.hasError)
                const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Album tracks could not be loaded. Check your connection and try again.',
                        style: TextStyle(color: HiHatColors.trace),
                      ),
                    ),
                  ),
                )
              else if (album.tracks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No playable tracks were returned for this album.',
                      style: TextStyle(color: HiHatColors.trace),
                    ),
                  ),
                )
              else ...[
                // Track Table Header
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: const SliverToBoxAdapter(
                    child: TrackTableHeader(secondaryColumnTitle: 'Plays'),
                  ),
                ),

                // Track Rows
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: SliverList.builder(
                    itemCount: album.tracks.length,
                    itemBuilder: (context, index) {
                      final track = album.tracks[index];
                      final plays = TrackTableRow.formatPlays(
                        index,
                        track.id.hashCode,
                      );

                      return TrackTableRow(
                        track: track,
                        secondaryText: plays,
                        onTap: () => ref
                            .read(audioEngineProvider.notifier)
                            .playNow(track),
                      );
                    },
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _playAll(List<TrackSummary> tracks) async {
    final start = ref.read(audioEngineProvider).queue.length;
    await ref.read(audioEngineProvider.notifier).addAllToQueue(tracks);
    await ref.read(audioEngineProvider.notifier).playAt(start);
  }
}
