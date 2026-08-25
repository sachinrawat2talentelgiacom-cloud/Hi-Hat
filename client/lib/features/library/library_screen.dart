import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../data/app_database.dart';
import '../../services/audio_engine.dart';
import '../../services/flac_metadata.dart';
import '../../services/library_service.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Local library'),
          actions: [
            IconButton(
              tooltip: 'Import local FLAC',
              onPressed: () => _import(context, ref),
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 12),
          ],
        ),
        library.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SliverFillRemaining(
            child: Center(
              child: Text('The local library could not be opened.'),
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
                          Icon(
                            Icons.library_music_outlined,
                            size: 52,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Your quiet archive',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Downloaded and imported FLAC files will remain available here offline.',
                          ),
                          const SizedBox(height: 24),
                          FilledButton.tonalIcon(
                            onPressed: () => _import(context, ref),
                            icon: const Icon(Icons.audio_file_outlined),
                            label: const Text('Import a FLAC'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (_, _) => const Divider(indent: 58),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return ListTile(
                        minTileHeight: 70,
                        leading: const SizedBox.square(
                          dimension: 44,
                          child: Icon(Icons.album_outlined),
                        ),
                        title: Text(track.title),
                        subtitle: Text(
                          '${track.artist}  ·  ${track.quality.display}',
                        ),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () => ref
                            .read(audioEngineProvider.notifier)
                            .playLocal(track),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
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
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    final title = metadata.title ?? p.basenameWithoutExtension(path);
    final artist = metadata.artist ?? 'Unknown artist';
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
            localPath: path,
            sha256: digest,
            codec: const Value('FLAC'),
            bitDepth: Value(metadata.bitDepth),
            sampleRate: Value(metadata.sampleRate),
            fileSize: bytes.length,
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title added to your library.')));
    }
  }
}
