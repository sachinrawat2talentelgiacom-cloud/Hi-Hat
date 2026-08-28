import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../models/album.dart';
import '../../services/download_service.dart';
import '../../services/provider_search_service.dart';
import '../../services/track_playback_coordinator.dart';
import '../../widgets/track_artwork.dart';
import '../player/song_actions.dart';
import 'search_controller.dart';
import 'album_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  Timer? debounce;
  AsyncValue<List<AlbumSummary>> albums = const AsyncValue.data([]);
  int albumGeneration = 0;

  Future<void> _searchAll(String value) async {
    ref.read(searchControllerProvider.notifier).search(value);
    final generation = ++albumGeneration;
    setState(() => albums = const AsyncValue.loading());
    try {
      final result = await ref
          .read(providerSearchServiceProvider)
          .searchAlbums(value);
      if (mounted && generation == albumGeneration) {
        setState(() => albums = AsyncValue.data(result));
      }
    } catch (error, stack) {
      if (mounted && generation == albumGeneration) {
        setState(() => albums = AsyncValue.error(error, stack));
      }
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchControllerProvider);
    final hasQuery = controller.text.trim().isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width < 700 ? 16 : 38,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi Hat',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          'Search',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Semantics(
                      label: 'Provider connection status',
                      child: const _SignalMark(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: MediaQuery.sizeOf(context).width >= 980,
                  style: Theme.of(context).textTheme.titleLarge,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, and albums',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(right: 18),
                      child: Icon(Icons.search, size: 24),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    debounce?.cancel();
                    if (value.trim().isEmpty) {
                      ref.read(searchControllerProvider.notifier).cancel();
                      return;
                    }
                    debounce = Timer(
                      const Duration(milliseconds: 500),
                      () => _searchAll(value),
                    );
                  },
                  onSubmitted: _searchAll,
                ),
                const SizedBox(height: 16),
                const _CalibrationLine(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: albums.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Album results are temporarily unavailable. Song results are shown below.',
              ),
            ),
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    height: 210,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (_, i) {
                        final album = items[i];
                        return SizedBox(
                          width: 150,
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => AlbumScreen(album: album),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TrackArtwork(
                                  artworkUrl: album.artworkUrl,
                                  size: 150,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  album.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  album.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
        search.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) {
            final providerUnavailable = error is ProviderSearchException;
            return SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchMessage(
                icon: Icons.cloud_off_outlined,
                title: providerUnavailable
                    ? 'Search source did not respond'
                    : 'Search could not be completed',
                body: providerUnavailable
                    ? 'Every configured music source is currently unavailable. Your local library and offline playback still work.'
                    : 'Try again shortly. Your local library remains available.',
                action: FilledButton.tonalIcon(
                  onPressed: () => ref
                      .read(searchControllerProvider.notifier)
                      .search(controller.text),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ),
            );
          },
          data: (results) {
            if (results.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _SearchMessage(
                  icon: hasQuery ? Icons.search_off : Icons.graphic_eq,
                  title: hasQuery
                      ? 'No tracks found'
                      : 'One search. One local copy.',
                  body: hasQuery
                      ? 'Try a different song, artist, or album name.'
                      : 'Find a track, verify the lossless source, and keep it on this device.',
                ),
              );
            }
            return SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 700 ? 16 : 38,
              ),
              sliver: SliverList.separated(
                itemCount: results.length,
                separatorBuilder: (_, _) => const Divider(indent: 82),
                itemBuilder: (context, index) => TrackResultTile(
                  track: results[index],
                  onPlay: () => _play(results[index]),
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 36)),
      ],
    );
  }

  Future<void> _play(TrackSummary track) async {
    final playTimer = Stopwatch()..start();
    final local = await ref
        .read(trackPlaybackCoordinatorProvider)
        .play(track, Navigator.of(context));
    if (!mounted) return;
    if (local != null) {
      debugPrint('local_play_latency_ms=${playTimer.elapsedMilliseconds}');
    } else {
      final transfer = ref.read(downloadServiceProvider).forTrack(track.id);
      if (transfer?.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(transfer!.error!)));
      }
    }
  }
}

class TrackResultTile extends ConsumerWidget {
  const TrackResultTile({super.key, required this.track, required this.onPlay});
  final TrackSummary track;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfer = ref.watch(downloadServiceProvider).forTrack(track.id);
    final active = transfer?.isActive ?? false;
    final progress = transfer?.progress ?? 0;
    final qualityLabel = track.isLocal
        ? track.quality.display
        : '${track.quality.display} listed';
    return Semantics(
      button: true,
      label: '${track.title} by ${track.artist}, $qualityLabel',
      child: InkWell(
        onTap: active
            ? () {
                ref.read(downloadServiceProvider.notifier).focus(track.id);
              }
            : onPlay,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TrackArtwork(
                artworkUrl: track.artworkUrl,
                size: 58,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (track.explicit) ...[
                          const _ExplicitBadge(),
                          const SizedBox(width: 6),
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
                    const SizedBox(height: 3),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (track.album != null) ...[
                          Flexible(
                            child: Text(
                              track.albumWithYear ?? track.album!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                          Text(
                            '  ·  ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                        ],
                        Text(
                          track.formattedDuration,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        if (track.tempoDisplay != null ||
                            track.musicalKeyDisplay != null) ...[
                          Text(
                            '  ·  ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              [
                                track.tempoDisplay,
                                track.musicalKeyDisplay,
                              ].whereType<String>().join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SongActionsButton(track: track),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    qualityLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  active
                      ? SizedBox(
                          width: 82,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LinearProgressIndicator(
                                value: progress > 0 ? progress : null,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${(progress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 30),
                ],
              ),
            ],
          ),
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

class _SignalMark extends StatelessWidget {
  const _SignalMark();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.graphic_eq, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      const Text('MONOCHROME'),
    ],
  );
}

class _CalibrationLine extends StatelessWidget {
  const _CalibrationLine();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        'FLAC',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Text('  ·  verified after download'),
      const SizedBox(width: 18),
      Expanded(
        child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      const SizedBox(width: 10),
      Icon(
        Icons.graphic_eq,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
    ],
  );
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    ),
  );
}
