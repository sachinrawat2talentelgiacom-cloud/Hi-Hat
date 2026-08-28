import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/album.dart';
import '../../models/track.dart';
import '../../services/audio_engine.dart';
import '../../services/provider_search_service.dart';
import '../../widgets/track_artwork.dart';
import '../player/song_actions.dart';

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Album')),
    body: FutureBuilder<AlbumSummary>(
      future: details,
      builder: (context, snapshot) {
        final album = snapshot.data ?? widget.album;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TrackArtwork(
                      artworkUrl: album.artworkUrl,
                      size: min(180, MediaQuery.sizeOf(context).width * .35),
                      highRes: true,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(album.artist),
                          if (album.releaseDate != null)
                            Text(album.releaseDate!),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: album.tracks.isEmpty
                                    ? null
                                    : () => _playAll(album.tracks),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Play album'),
                              ),
                              OutlinedButton.icon(
                                onPressed: album.tracks.isEmpty
                                    ? null
                                    : () => ref
                                          .read(audioEngineProvider.notifier)
                                          .addAllToQueue(album.tracks),
                                icon: const Icon(Icons.queue_music),
                                label: const Text('Add to queue'),
                              ),
                              IconButton(
                                tooltip: 'Shuffle album',
                                onPressed: album.tracks.isEmpty
                                    ? null
                                    : () {
                                        final tracks = [...album.tracks]
                                          ..shuffle();
                                        _playAll(tracks);
                                      },
                                icon: const Icon(Icons.shuffle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Album tracks could not be loaded. Check your connection and try again.',
                    ),
                  ),
                ),
              )
            else if (album.tracks.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No playable tracks were returned for this album.',
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: album.tracks.length,
                itemBuilder: (_, i) {
                  final t = album.tracks[i];
                  return ListTile(
                    leading: Text('${i + 1}'),
                    title: Text(t.displayTitle),
                    subtitle: Text('${t.artist} · ${t.formattedDuration}'),
                    onTap: () =>
                        ref.read(audioEngineProvider.notifier).playNow(t),
                    trailing: SongActionsButton(track: t),
                  );
                },
              ),
          ],
        );
      },
    ),
  );
  Future<void> _playAll(List<TrackSummary> tracks) async {
    final start = ref.read(audioEngineProvider).queue.length;
    await ref.read(audioEngineProvider.notifier).addAllToQueue(tracks);
    await ref.read(audioEngineProvider.notifier).playAt(start);
  }
}
