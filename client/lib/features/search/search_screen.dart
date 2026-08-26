import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../services/download_service.dart';
import '../../services/provider_search_service.dart';
import '../../services/track_playback_coordinator.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  Timer? debounce;

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
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 700 ? 24 : 46,
            32,
            32,
            14,
          ),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Text(
                    'Hi Hat',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const Spacer(),
                  Semantics(
                    label: 'Provider connection status',
                    child: const _SignalMark(),
                  ),
                ],
              ),
              const SizedBox(height: 54),
              TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: MediaQuery.sizeOf(context).width >= 980,
                style: Theme.of(context).textTheme.displayMedium,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search for a song',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(right: 18),
                    child: Icon(Icons.search, size: 36),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
                onChanged: (value) {
                  debounce?.cancel();
                  debounce = Timer(const Duration(seconds: 2), () {
                    ref.read(searchControllerProvider.notifier).search(value);
                  });
                },
                onSubmitted: (value) =>
                    ref.read(searchControllerProvider.notifier).search(value),
              ),
              const SizedBox(height: 22),
              const _CalibrationLine(),
              const SizedBox(height: 32),
            ],
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
                  icon: controller.text.isEmpty
                      ? Icons.graphic_eq
                      : Icons.search_off,
                  title: controller.text.isEmpty
                      ? 'One search. One local copy.'
                      : 'No tracks found',
                  body: controller.text.isEmpty
                      ? 'Find a track, verify the lossless source, and keep it on this device.'
                      : 'Try a different song, artist, or album name.',
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
      final error = ref.read(downloadServiceProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'The download failed. Try again.')),
      );
    }
  }
}

class TrackResultTile extends ConsumerWidget {
  const TrackResultTile({super.key, required this.track, required this.onPlay});
  final TrackSummary track;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfer = ref.watch(downloadServiceProvider);
    final active =
        transfer.trackId == track.id &&
        const {
          'OPENING_PROVIDER',
          'AUTH_REQUIRED',
          'MATCHING_TRACK',
          'STARTING_DOWNLOAD',
          'PREPARING_AUDIO',
          'DOWNLOADING',
          'VERIFYING',
          'FINALIZING',
        }.contains(transfer.phase);
    final qualityLabel = track.isLocal
        ? track.quality.display
        : '${track.quality.display} listed';
    return Semantics(
      button: true,
      label: '${track.title} by ${track.artist}, $qualityLabel',
      child: InkWell(
        onTap: active ? null : onPlay,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              _Artwork(track: track, size: 58),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (track.album != null)
                      Text(
                        track.album!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    qualityLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  active
                      ? SizedBox(
                          width: 82,
                          child: LinearProgressIndicator(
                            value: transfer.progress > 0
                                ? transfer.progress
                                : null,
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

class _Artwork extends StatelessWidget {
  const _Artwork({required this.track, required this.size});
  final TrackSummary track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = track.artworkUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: const Icon(Icons.album_outlined),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Icon(Icons.album_outlined),
                ),
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
