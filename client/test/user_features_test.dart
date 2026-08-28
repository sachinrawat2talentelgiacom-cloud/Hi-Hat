import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hi_hat/models/track.dart';
import 'package:hi_hat/services/user_data_store.dart';

const track = TrackSummary(
  id: 'local:1',
  provider: 'local',
  providerTrackId: '1',
  title: 'Song',
  artist: 'Artist',
  localPath: 'song.flac',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('track serialization preserves queue and playlist fields', () {
    final restored = TrackSummary.fromJson(track.toJson());
    expect(restored.id, track.id);
    expect(restored.localPath, track.localPath);
    expect(restored.artist, track.artist);
  });

  test(
    'playlists reject duplicate names and preserve duplicate songs',
    () async {
      final controller = PlaylistController();
      await Future<void>.delayed(Duration.zero);
      expect(await controller.create('Road Trip'), isNull);
      expect(await controller.create('road trip'), isNotNull);
      final id = controller.state.playlists.single.id;
      await controller.addTrack(id, track);
      await controller.addTrack(id, track);
      expect(controller.state.playlists.single.tracks, hasLength(2));
      controller.dispose();
    },
  );

  test('playlists rename, reorder, remove, delete and restore', () async {
    final controller = PlaylistController();
    await Future<void>.delayed(Duration.zero);
    await controller.create('Old');
    final id = controller.state.playlists.single.id;
    await controller.addTrack(id, track);
    await controller.addTrack(
      id,
      TrackSummary.fromJson({
        ...track.toJson(),
        'id': 'local:2',
        'provider_track_id': '2',
        'title': 'Second',
      }),
    );
    await controller.reorder(id, 0, 1);
    expect(controller.state.playlists.single.tracks.first.title, 'Second');
    expect(await controller.rename(id, 'New'), isNull);
    await controller.removeTrack(id, 0);
    final restored = PlaylistController();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(restored.state.playlists.single.name, 'New');
    expect(restored.state.playlists.single.tracks, hasLength(1));
    await restored.delete(id);
    expect(restored.state.playlists, isEmpty);
    controller.dispose();
    restored.dispose();
  });
}
