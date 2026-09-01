import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/scroll_behavior.dart';
import '../../models/track.dart';
import '../../services/artist_preferences_store.dart';
import '../../services/audio_engine.dart';
import '../../services/discovery_service.dart';
import '../../services/download_service.dart';
import '../../services/library_service.dart';
import '../../services/provider_search_service.dart';
import '../../services/track_playback_coordinator.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/track_artwork.dart';
import '../../widgets/hi_hat_surface.dart';
import '../../widgets/brand_widgets.dart';
import '../player/song_actions.dart';
import '../search/discovery_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _pageSize = 20;

  bool pickerVisible = false;
  int visibleDiscoveryTracks = _pageSize;
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = SmoothScrollController(debugLabel: 'home');
    scrollController.addListener(_loadNextDiscoveryPage);
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(_loadNextDiscoveryPage)
      ..dispose();
    super.dispose();
  }

  void _loadNextDiscoveryPage() {
    if (!scrollController.hasClients ||
        scrollController.position.extentAfter > 900) {
      return;
    }
    final tracks = ref.read(discoveryControllerProvider).valueOrNull;
    if (tracks == null || visibleDiscoveryTracks >= tracks.length) return;
    setState(() {
      visibleDiscoveryTracks = (visibleDiscoveryTracks + _pageSize).clamp(
        0,
        tracks.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final discovery = ref.watch(discoveryControllerProvider);
    final playback = ref.watch(audioEngineProvider);
    final library = ref.watch(libraryProvider);
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 700 ? 16.0 : 28.0;
    ref.listen<AsyncValue<List<TrackSummary>>>(discoveryControllerProvider, (
      previous,
      next,
    ) {
      final previousTracks = previous?.valueOrNull;
      final nextTracks = next.valueOrNull;
      if (nextTracks != null && !identical(previousTracks, nextTracks)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => visibleDiscoveryTracks = _pageSize);
        });
      }
      if (next is AsyncData &&
          !ref.read(discoveryControllerProvider.notifier).hasArtists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showArtistPicker(firstRun: true);
        });
      }
    });

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontal, 30, horizontal, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HiHatEyebrow('Hi Hat / home'),
                const SizedBox(height: 8),
                Text(
                  'Listening now',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 24),
                _ListeningStage(playback: playback),
              ],
            ),
          ),
        ),
        library.when(
          loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (tracks) => tracks.isEmpty
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        16,
                        horizontal,
                        12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 10,
                          children: [
                            Text(
                              'Ready locally',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const HiHatStatusChip(
                              label: 'Available offline',
                              icon: Icons.offline_pin_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      sliver: SliverList.builder(
                        itemCount: tracks.length.clamp(0, 4),
                        itemBuilder: (context, index) => TrackTableRow(
                          track: tracks[index],
                          secondaryText: tracks[index].quality.display,
                          onTap: () => ref
                              .read(audioEngineProvider.notifier)
                              .playLocal(tracks[index]),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 38)),
                  ],
                ),
        ),
        _buildDiscoverySliver(discovery),
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }

  Widget _buildDiscoverySliver(AsyncValue<List<TrackSummary>> discovery) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 700 ? 16.0 : 28.0;

    return discovery.when(
      loading: () => const SliverFillRemaining(child: TrackGridSkeleton()),
      error: (_, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: _HomeMessage(
          icon: Icons.wifi_tethering_error_rounded,
          title: 'Discovery source did not respond',
          body: 'Refresh when your connection is ready, or search for a specific track. Existing local music remains available.',
          action: FilledButton.tonalIcon(
            onPressed: () =>
                ref.read(discoveryControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh feed'),
          ),
        ),
      ),
      data: (tracks) {
        final visibleTracks = tracks
            .take(visibleDiscoveryTracks)
            .toList(growable: false);
        final preferences = ref.read(discoveryControllerProvider.notifier);
        if (!preferences.hasArtists) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _HomeMessage(
              icon: Icons.library_music_outlined,
              title: 'Choose artists you return to',
              body: 'Hi Hat will build a local preference-based feed from artist and genre searches.',
              action: FilledButton.icon(
                onPressed: () => _showArtistPicker(firstRun: true),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Choose artists'),
              ),
            ),
          );
        }
        if (tracks.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _HomeMessage(
              icon: Icons.album_outlined,
              title: 'No discovery tracks found',
              body: 'Your preferences are saved. Try refreshing or editing your artists and genres.',
              action: FilledButton.tonalIcon(
                onPressed: preferences.refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh feed'),
              ),
            ),
          );
        }

        final topTrack = tracks.first;
        final artistList = preferences.artists;
        final heroTitle =
            topTrack.album != null && topTrack.album!.trim().isNotEmpty
            ? topTrack.album!
            : (topTrack.displayTitle.isNotEmpty
                  ? topTrack.displayTitle
                  : 'Featured Album');
        final heroSubtitle = artistList.isNotEmpty
            ? 'By ${artistList.take(3).join(', ')}'
            : 'By ${topTrack.artist}';

        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HiHatEyebrow('Discovery'),
                          const SizedBox(height: 8),
                          Text(
                            'A few paths into the catalog',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontFamily: 'Lora'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$heroTitle · $heroSubtitle',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: HiHatColors.trace),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      tooltip: 'Edit discovery preferences',
                      onPressed: () => _showArtistPicker(firstRun: false),
                      style: IconButton.styleFrom(
                        backgroundColor: HiHatColors.signal,
                        foregroundColor: HiHatColors.onSignal,
                      ),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),
              ),
            ),

            // Section Header with Shuffle & Reload action
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 16),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 10,
                  children: [
                    const Text(
                      'From your preferences',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(discoveryControllerProvider.notifier)
                          .shuffleAndReload(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2E3244)),
                        backgroundColor: const Color(0xFF14161E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: HiHatColors.coral,
                      ),
                      label: const Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Big Cover Art Card Blocks Grid
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.74,
                ),
                itemCount: visibleTracks.length,
                itemBuilder: (context, index) {
                  final track = visibleTracks[index];
                  return TrackCardBlock(
                    track: track,
                    onTap: () => _play(track),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showArtistPicker({required bool firstRun}) async {
    if (pickerVisible || !mounted) return;
    pickerVisible = true;
    final controller = ref.read(discoveryControllerProvider.notifier);
    final result = await showDialog<ArtistPreferences>(
      context: context,
      barrierDismissible: !firstRun,
      builder: (context) => ArtistPreferenceDialog(
        initialArtists: controller.artists,
        initialGenres: controller.genres,
        firstRun: firstRun,
      ),
    );
    pickerVisible = false;
    if (result == null || !mounted) return;
    try {
      await controller.updatePreferences(
        artists: result.artists,
        genres: result.genres,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hi Hat could not save those preferences. Please try again.',
            ),
          ),
        );
      }
    }
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

class _ListeningStage extends ConsumerWidget {
  const _ListeningStage({required this.playback});

  final PlaybackState playback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = playback.track;
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 480;
    if (track == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            HiHatMark(size: 58),
            SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your listening room is quiet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Find a track or choose something stored on this device.',
                    style: TextStyle(color: HiHatColors.trace),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          TrackArtwork(
            artworkUrl: track.highResArtworkUrl ?? track.artworkUrl,
            size: compact ? 76 : 112,
            borderRadius: BorderRadius.circular(10),
          ),
          SizedBox(width: compact ? 14 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HiHatEyebrow(
                  playback.playing ? 'Playing in the chamber' : 'Ready locally',
                  color: playback.playing
                      ? HiHatColors.signal
                      : HiHatColors.brandGreen,
                ),
                const SizedBox(height: 7),
                Text(
                  track.displayTitle,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  track.album == null
                      ? track.artist
                      : '${track.artist} · ${track.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: HiHatColors.trace),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 16),
          FilledButton(
            onPressed: () => ref.read(audioEngineProvider.notifier).toggle(),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              minimumSize: Size.square(compact ? 52 : 64),
            ),
            child: Icon(
              playback.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: compact ? 27 : 32,
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoveryTrackCard extends ConsumerWidget {
  const DiscoveryTrackCard({
    super.key,
    required this.track,
    required this.onPlay,
  });

  final TrackSummary track;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfer = ref.watch(downloadServiceProvider).forTrack(track.id);
    final active = transfer?.isActive ?? false;
    final progress = transfer?.progress ?? 0;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '${track.displayTitle} by ${track.artist}',
      child: InkWell(
        onTap: active
            ? () => ref.read(downloadServiceProvider.notifier).focus(track.id)
            : onPlay,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TrackArtwork(
                    artworkUrl: track.artworkUrl ?? track.highResArtworkUrl,
                    highRes: false,
                    width: double.infinity,
                    height: double.infinity,
                    iconSize: 48,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  if (active)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Material(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress > 0 ? progress : null,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Text(
                                '${(progress * 100).round()}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Text(
              track.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 3),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SongActionsButton(track: track),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtistPreferenceDialog extends ConsumerStatefulWidget {
  const ArtistPreferenceDialog({
    super.key,
    required this.initialArtists,
    required this.initialGenres,
    required this.firstRun,
  });

  final List<String> initialArtists;
  final Set<String> initialGenres;
  final bool firstRun;

  @override
  ConsumerState<ArtistPreferenceDialog> createState() =>
      _ArtistPreferenceDialogState();
}

class _ArtistPreferenceDialogState
    extends ConsumerState<ArtistPreferenceDialog> {
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  Timer? debounce;
  late final List<String> selectedArtists;
  late final Set<String> selectedGenres;
  AsyncValue<List<String>> suggestions = const AsyncValue.data([]);

  @override
  void initState() {
    super.initState();
    selectedArtists = [...widget.initialArtists];
    selectedGenres = {...widget.initialGenres};
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchArtists(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      if (mounted) setState(() => suggestions = const AsyncValue.data([]));
      return;
    }
    setState(() => suggestions = const AsyncValue.loading());
    try {
      final tracks = await ref
          .read(providerSearchServiceProvider)
          .search(clean, limit: 16);
      if (!mounted || searchController.text.trim() != clean) return;
      final seen = <String>{};
      final artists = tracks
          .map((track) => track.artist.trim())
          .where((artist) => artist.isNotEmpty)
          .where((artist) => seen.add(artist.toLowerCase()))
          .take(8)
          .toList(growable: false);
      setState(() => suggestions = AsyncValue.data(artists));
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => suggestions = AsyncValue.error(error, stackTrace));
      }
    }
  }

  void _addArtist(String artist) {
    final clean = artist.trim();
    if (clean.isEmpty ||
        selectedArtists.any(
          (existing) => existing.toLowerCase() == clean.toLowerCase(),
        )) {
      return;
    }
    setState(() {
      selectedArtists.add(clean);
      searchController.clear();
      suggestions = const AsyncValue.data([]);
    });
    searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.library_music_outlined),
      title: Text(
        widget.firstRun ? 'Tune your home feed' : 'Your discovery mix',
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose artists you like. Hi Hat uses ordinary artist and genre searches to assemble this feed.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Find an artist',
                  hintText: 'Type an artist name',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Add typed artist',
                    onPressed: () => _addArtist(searchController.text),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                onChanged: (value) {
                  debounce?.cancel();
                  debounce = Timer(
                    const Duration(milliseconds: 450),
                    () => _searchArtists(value),
                  );
                },
                onSubmitted: _addArtist,
              ),
              suggestions.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: LinearProgressIndicator(),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Artist suggestions are unavailable. You can still add the typed name.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                data: (artists) => artists.isEmpty
                    ? const SizedBox(height: 12)
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: artists
                              .map(
                                (artist) => ActionChip(
                                  avatar: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 18,
                                  ),
                                  label: Text(artist),
                                  onPressed: () => _addArtist(artist),
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
              if (selectedArtists.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Selected artists', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedArtists
                      .map(
                        (artist) => InputChip(
                          label: Text(artist),
                          onDeleted: () =>
                              setState(() => selectedArtists.remove(artist)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              Text('Optional genres', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'These broaden the search seeds used alongside your artists.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DiscoveryService.availableGenres.map((genre) {
                  return FilterChip(
                    label: Text(genre),
                    selected: selectedGenres.contains(genre),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedGenres.add(genre);
                        } else {
                          selectedGenres.remove(genre);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!widget.firstRun)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        FilledButton(
          onPressed: selectedArtists.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  ArtistPreferences(
                    artists: selectedArtists,
                    genres: selectedGenres,
                  ),
                ),
          child: Text(widget.firstRun ? 'Build my feed' : 'Save preferences'),
        ),
      ],
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
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
