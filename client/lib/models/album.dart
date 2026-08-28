import 'track.dart';

class AlbumSummary {
  const AlbumSummary({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.releaseDate,
    this.tracks = const [],
  });
  final String id, title, artist;
  final String? artworkUrl, releaseDate;
  final List<TrackSummary> tracks;
  AlbumSummary copyWith({List<TrackSummary>? tracks}) => AlbumSummary(
    id: id,
    title: title,
    artist: artist,
    artworkUrl: artworkUrl,
    releaseDate: releaseDate,
    tracks: tracks ?? this.tracks,
  );
}
