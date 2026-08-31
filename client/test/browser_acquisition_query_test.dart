import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/features/browser_acquisition/browser_acquisition_screen.dart';
import 'package:hi_hat/models/track.dart';

void main() {
  test('provider query uses title and primary artist only', () {
    const track = TrackSummary(
      id: 'monochrome:1',
      provider: 'monochrome',
      providerTrackId: '1',
      title: 'Spoil My Night',
      artist: 'Post Malone, Swae Lee',
      album: 'beerbongs & bentleys',
      quality: AudioQuality(),
    );

    expect(acquisitionSearchQuery(track), 'Spoil My Night Post Malone');
  });

  test('provider query understands featured-artist credits', () {
    const track = TrackSummary(
      id: 'monochrome:2',
      provider: 'monochrome',
      providerTrackId: '2',
      title: 'Song',
      artist: 'Lead Artist feat. Guest Artist',
      quality: AudioQuality(),
    );

    expect(acquisitionSearchQuery(track), 'Song Lead Artist');
  });
}
