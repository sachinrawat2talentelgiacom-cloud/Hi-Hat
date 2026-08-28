import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../services/audio_engine.dart';
import '../../services/user_data_store.dart';
import '../../services/track_playback_coordinator.dart';

class SongActionsButton extends ConsumerWidget {
  const SongActionsButton({
    super.key,
    required this.track,
    this.playlistId,
    this.playlistIndex,
  });
  final TrackSummary track;
  final String? playlistId;
  final int? playlistIndex;
  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(
    tooltip: 'More actions for ${track.displayTitle}',
    onSelected: (value) async {
      if (value == 'queue') {
        await ref.read(audioEngineProvider.notifier).addToQueue(track);
        if (context.mounted) _message(context, 'Added to queue');
      }
      if (value == 'play') {
        if (track.isLocal) {
          await ref.read(audioEngineProvider.notifier).playNow(track);
        } else if (context.mounted) {
          await ref
              .read(trackPlaybackCoordinatorProvider)
              .play(track, Navigator.of(context));
        }
      }
      if (value == 'playlist' && context.mounted) {
        await showAddToPlaylist(context, ref, track);
      }
      if (value == 'remove' && playlistId != null && playlistIndex != null) {
        await ref
            .read(playlistProvider.notifier)
            .removeTrack(playlistId!, playlistIndex!);
      }
    },
    itemBuilder: (_) => [
      const PopupMenuItem(
        value: 'play',
        child: ListTile(
          leading: Icon(Icons.play_arrow),
          title: Text('Play now'),
        ),
      ),
      const PopupMenuItem(
        value: 'queue',
        child: ListTile(
          leading: Icon(Icons.queue_music),
          title: Text('Add to queue'),
        ),
      ),
      const PopupMenuItem(
        value: 'playlist',
        child: ListTile(
          leading: Icon(Icons.playlist_add),
          title: Text('Add to playlist'),
        ),
      ),
      if (playlistId != null)
        const PopupMenuItem(
          value: 'remove',
          child: ListTile(
            leading: Icon(Icons.remove_circle_outline),
            title: Text('Remove from playlist'),
          ),
        ),
    ],
  );
}

Future<void> showAddToPlaylist(
  BuildContext context,
  WidgetRef ref,
  TrackSummary track,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(playlistProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Add to playlist'),
                  trailing: IconButton(
                    tooltip: 'Create playlist',
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final name = await _askName(context, 'Create playlist');
                      if (name == null) return;
                      final error = await ref
                          .read(playlistProvider.notifier)
                          .create(name);
                      if (error != null && context.mounted) {
                        _message(context, error);
                      }
                    },
                  ),
                ),
                if (state.loading)
                  const CircularProgressIndicator()
                else if (state.playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No playlists yet. Create one with the + button.',
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final playlist in state.playlists)
                          ListTile(
                            leading: const Icon(Icons.queue_music),
                            title: Text(playlist.name),
                            subtitle: Text('${playlist.tracks.length} songs'),
                            onTap: () async {
                              await ref
                                  .read(playlistProvider.notifier)
                                  .addTrack(playlist.id, track);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<String?> askPlaylistName(
  BuildContext context,
  String title, {
  String initial = '',
}) => _askName(context, title, initial: initial);
Future<String?> _askName(
  BuildContext context,
  String title, {
  String initial = '',
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 80,
        decoration: const InputDecoration(labelText: 'Playlist name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

void _message(BuildContext context, String value) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
