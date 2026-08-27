import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/models/track.dart';
import 'package:hi_hat/services/download_service.dart';

void main() {
  test(
    'DownloadService tracks multiple downloads concurrently in parallel',
    () {
      final service = DownloadService();
      const trackA = TrackSummary(
        id: 'monochrome:1',
        provider: 'monochrome',
        providerTrackId: '1',
        title: 'Track A',
        artist: 'Artist A',
        quality: AudioQuality(),
      );
      const trackB = TrackSummary(
        id: 'monochrome:2',
        provider: 'monochrome',
        providerTrackId: '2',
        title: 'Track B',
        artist: 'Artist B',
        quality: AudioQuality(),
      );

      // Start track A
      service.begin(trackA.id, track: trackA);
      expect(service.state.activeTransfers.length, 1);
      expect(service.state.forTrack(trackA.id)?.phase, 'OPENING_PROVIDER');
      expect(service.state.forTrack(trackA.id)?.isActive, isTrue);
      expect(service.state.forTrack(trackA.id)?.isMinimized, isTrue);

      // Start track B concurrently
      service.begin(trackB.id, track: trackB);
      expect(service.state.activeTransfers.length, 2);
      expect(service.state.forTrack(trackB.id)?.phase, 'OPENING_PROVIDER');

      // Update track A to DOWNLOADING at 45%
      service.update(trackA.id, 'DOWNLOADING', progress: 0.45);
      // Update track B to MATCHING_TRACK at 10%
      service.update(trackB.id, 'MATCHING_TRACK', progress: 0.10);

      expect(service.state.forTrack(trackA.id)?.progress, 0.45);
      expect(service.state.forTrack(trackA.id)?.phase, 'DOWNLOADING');

      expect(service.state.forTrack(trackB.id)?.progress, 0.10);
      expect(service.state.forTrack(trackB.id)?.phase, 'MATCHING_TRACK');

      // Minimize track A
      service.setMinimized(trackA.id, true);
      expect(service.state.forTrack(trackA.id)?.isMinimized, isTrue);
      expect(service.state.forTrack(trackB.id)?.isMinimized, isTrue);

      // Focus track A (should restore from minimized)
      service.focus(trackA.id);
      expect(service.state.forTrack(trackA.id)?.isMinimized, isFalse);
      expect(service.state.focusedTrackId, trackA.id);

      // Complete track A
      service.complete(trackA.id);
      expect(service.state.forTrack(trackA.id)?.isCompleted, isTrue);
      expect(service.state.forTrack(trackA.id)?.isActive, isFalse);
      expect(service.state.activeTransfers.length, 1);
      expect(service.state.activeTransfers.first.trackId, trackB.id);

      // Fail track B
      service.fail(trackB.id, 'Network error');
      expect(service.state.forTrack(trackB.id)?.isFailed, isTrue);
      expect(service.state.forTrack(trackB.id)?.error, 'Network error');
      expect(service.state.activeTransfers.length, 0);
    },
  );

  test('cancel hides immediately and removal permits a clean restart', () {
    final service = DownloadService();
    const track = TrackSummary(
      id: 'monochrome:cancel',
      provider: 'monochrome',
      providerTrackId: 'cancel',
      title: 'Cancelled Track',
      artist: 'Artist',
      quality: AudioQuality(),
    );

    service.begin(track.id, track: track);
    service.update(track.id, 'DOWNLOADING', progress: 0.5);
    service.cancel(track.id);

    expect(service.state.forTrack(track.id)?.isCancelled, isTrue);
    expect(service.state.activeTransfers, isEmpty);

    service.remove(track.id);
    expect(service.state.forTrack(track.id), isNull);

    service.begin(track.id, track: track);
    final restarted = service.state.forTrack(track.id);
    expect(restarted?.phase, 'OPENING_PROVIDER');
    expect(restarted?.progress, 0.02);
    expect(restarted?.isMinimized, isTrue);
  });
}
