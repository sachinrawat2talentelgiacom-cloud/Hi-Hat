import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../models/track.dart';
import '../../services/audio_engine.dart';
import '../../services/flac_metadata.dart';
import '../../services/file_integrity.dart';
import '../../services/library_folder_service.dart';
import '../../services/library_service.dart';
import '../../widgets/app_widgets.dart';
import '../../services/user_data_store.dart';
import '../player/song_actions.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool scanning = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_scanFolder);
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final playlists = ref.watch(playlistProvider);
    final playback = ref.watch(audioEngineProvider);
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 700 ? 16.0 : 28.0;

    return CustomScrollView(
      slivers: [
        // Action Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
            child: Row(
              children: [
                const Text(
                  'Local Library',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Create playlist',
                  onPressed: () async {
                    final name =
                        await askPlaylistName(context, 'Create playlist');
                    if (name != null && name.trim().isNotEmpty) {
                      final error = await ref
                          .read(playlistProvider.notifier)
                          .create(name.trim());
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(error)));
                      }
                    }
                  },
                  icon: const Icon(Icons.playlist_add_rounded,
                      color: HiHatColors.trace),
                ),
                IconButton(
                  tooltip: 'Scan music folder',
                  onPressed: scanning ? null : _scanFolder,
                  icon: scanning
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: HiHatColors.coral,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, color: HiHatColors.trace),
                ),
                IconButton(
                  tooltip: 'Import local FLAC',
                  onPressed: () => _import(context, ref),
                  icon: const Icon(Icons.add_rounded, color: HiHatColors.trace),
                ),
              ],
            ),
          ),
        ),

        // Hero Banner if tracks exist
        library.when(
          loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (tracks) {
            if (tracks.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
            final firstTrack = tracks.first;

            return SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
              sliver: SliverToBoxAdapter(
                child: HeroBanner(
                  title: 'FLAC Archive',
                  subtitle: '${tracks.length} local tracks ready offline',
                  artworkUrl: firstTrack.artworkUrl,
                  songCountText: '${tracks.length} songs',
                  durationText: 'Lossless FLAC',
                  qualityBadge: 'FLAC 100%',
                  isPlaying: playback.playing,
                  onPlayAll: () => _playAll(tracks),
                  onShuffle: () {
                    final shuffled = [...tracks]..shuffle();
                    _playAll(shuffled);
                  },
                  onEdit: () => _import(context, ref),
                  onMore: _scanFolder,
                ),
              ),
            );
          },
        ),

        // Playlists Section
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          sliver: SliverToBoxAdapter(child: _PlaylistsSection(state: playlists)),
        ),

        // Track List Table
        library.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: HiHatColors.coral),
            ),
          ),
          error: (_, _) => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'The local library could not be opened.',
                style: TextStyle(color: HiHatColors.trace),
              ),
            ),
          ),
          data: (tracks) => tracks.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.library_music_outlined,
                            size: 52,
                            color: HiHatColors.coral,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Your quiet archive',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Downloaded and imported FLAC files will remain available here offline.',
                            style: TextStyle(color: HiHatColors.trace),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => _import(context, ref),
                            icon: const Icon(Icons.audio_file_outlined),
                            label: const Text('Import a FLAC'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      sliver: const SliverToBoxAdapter(
                        child: TrackTableHeader(secondaryColumnTitle: 'Quality'),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      sliver: SliverList.builder(
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return TrackTableRow(
                            track: track,
                            secondaryText: track.quality.display,
                            onTap: () => ref
                                .read(audioEngineProvider.notifier)
                                .playLocal(track),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }

  Future<void> _playAll(List<TrackSummary> tracks) async {
    if (tracks.isEmpty) return;
    await ref.read(audioEngineProvider.notifier).clearQueue();
    await ref.read(audioEngineProvider.notifier).addAllToQueue(tracks);
    await ref.read(audioEngineProvider.notifier).playLocal(tracks.first);
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['flac'],
    );
    final path = result?.path;
    if (path == null) return;
    final file = File(path);
    late final FlacMetadata metadata;
    try {
      metadata = await FlacMetadataReader.read(file);
    } on FormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
      return;
    } on FileSystemException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hi Hat could not read that file.')),
        );
      }
      return;
    }
    final fileSize = await file.length();
    final digest = await sha256File(file);
    final title = metadata.title ?? p.basenameWithoutExtension(path);
    final artist = metadata.artist ?? 'Unknown artist';
    final artworkPath = metadata.picture != null
        ? await LibraryFolderService.saveCoverArt(
            digest,
            metadata.picture!.data,
            metadata.picture!.mimeType,
          )
        : await LibraryFolderService.findDirectoryCover(file.parent);

    await ref
        .read(databaseProvider)
        .saveTrack(
          TracksCompanion.insert(
            id: 'local:$digest',
            provider: 'local',
            providerTrackId: digest,
            title: title,
            artist: artist,
            album: Value(metadata.album),
            artworkUrl: Value(artworkPath),
            localPath: path,
            sha256: digest,
            codec: const Value('FLAC'),
            bitDepth: Value(metadata.bitDepth),
            sampleRate: Value(metadata.sampleRate),
            channels: Value(metadata.channels),
            durationSeconds: Value(metadata.durationSeconds),
            fileSize: fileSize,
            year: Value(metadata.year),
            trackNumber: Value(metadata.trackNumber),
            discNumber: Value(metadata.discNumber),
            genre: Value(metadata.genre),
            bpm: Value(metadata.bpm),
            key: Value(metadata.key),
            isrc: Value(metadata.isrc),
            copyright: Value(metadata.copyright),
            replayGain: Value(metadata.replayGain),
            peak: Value(metadata.peak),
            version: Value(metadata.version),
            audioQualityLabel: const Value('FLAC'),
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title added to your library.')));
    }
  }

  Future<void> _scanFolder() async {
    if (scanning) return;
    setState(() => scanning = true);
    try {
      await ref.read(libraryFolderServiceProvider).scanConfiguredFolder();
    } on FileSystemException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The music folder is unavailable. Choose it again in Settings.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }
}

class _PlaylistsSection extends ConsumerWidget {
  const _PlaylistsSection({required this.state});
  final PlaylistState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading) return const LinearProgressIndicator();
    if (state.playlists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: Text('Custom playlists will appear here.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Playlists',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final playlist in state.playlists)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.queue_music),
                title: Text(playlist.name),
                subtitle: Text('${playlist.tracks.length} songs'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'rename') {
                      final name = await askPlaylistName(
                        context,
                        'Rename playlist',
                        initial: playlist.name,
                      );
                      if (name != null) {
                        final error = await ref
                            .read(playlistProvider.notifier)
                            .rename(playlist.id, name);
                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(error)));
                        }
                      }
                    }
                    if (value == 'delete' && context.mounted) {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Delete ${playlist.name}?'),
                          content: const Text(
                            'This removes the playlist, not downloaded songs.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (yes == true) {
                        await ref
                            .read(playlistProvider.notifier)
                            .delete(playlist.id);
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                children: [
                  if (playlist.tracks.isEmpty)
                    const ListTile(
                      title: Text(
                        'This playlist is empty. Add songs from any song menu.',
                      ),
                    ),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: playlist.tracks.length,
                    onReorderItem: (a, b) => ref
                        .read(playlistProvider.notifier)
                        .reorder(playlist.id, a, b),
                    itemBuilder: (_, i) {
                      final track = playlist.tracks[i];
                      return ListTile(
                        key: ValueKey('${playlist.id}:$i:${track.id}'),
                        title: Text(track.displayTitle),
                        subtitle: Text(track.artist),
                        onTap: () => ref
                            .read(audioEngineProvider.notifier)
                            .playNow(track),
                        trailing: SongActionsButton(
                          track: track,
                          playlistId: playlist.id,
                          playlistIndex: i,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
