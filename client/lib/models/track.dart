class AudioQuality {
  const AudioQuality({
    this.codec,
    this.lossless = false,
    this.bitDepth,
    this.sampleRate,
    this.label,
  });

  final String? codec;
  final bool lossless;
  final int? bitDepth;
  final int? sampleRate;
  final String? label;

  factory AudioQuality.fromJson(Map<String, dynamic>? json) => json == null
      ? const AudioQuality()
      : AudioQuality(
          codec: json['codec'] as String?,
          lossless: json['lossless'] as bool? ?? false,
          bitDepth: json['bit_depth'] as int?,
          sampleRate: json['sample_rate'] as int?,
          label: json['label'] as String?,
        );

  String get display {
    final parts = <String>[
      codec ?? (lossless ? 'Lossless' : 'Quality pending'),
    ];
    if (bitDepth != null) parts.add('$bitDepth-bit');
    if (sampleRate != null) {
      final khz = sampleRate! / 1000;
      parts.add(
        '${khz == khz.roundToDouble() ? khz.round() : khz.toStringAsFixed(1)} kHz',
      );
    }
    return parts.join(' · ');
  }
}

class TrackSummary {
  const TrackSummary({
    required this.id,
    required this.provider,
    required this.providerTrackId,
    required this.title,
    required this.artist,
    this.album,
    this.artworkUrl,
    this.durationSeconds,
    this.explicit = false,
    this.quality = const AudioQuality(),
    this.localPath,
  });

  final String id;
  final String provider;
  final String providerTrackId;
  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  final double? durationSeconds;
  final bool explicit;
  final AudioQuality quality;
  final String? localPath;
  bool get isLocal => localPath != null;

  factory TrackSummary.fromJson(Map<String, dynamic> json) => TrackSummary(
    id: json['id'] as String,
    provider: json['provider'] as String,
    providerTrackId: json['provider_track_id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    album: json['album'] as String?,
    artworkUrl: json['artwork_url'] as String?,
    durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
    explicit: json['explicit'] as bool? ?? false,
    quality: AudioQuality.fromJson(
      json['available_quality'] as Map<String, dynamic>?,
    ),
  );

  TrackSummary copyWith({String? localPath, AudioQuality? quality}) =>
      TrackSummary(
        id: id,
        provider: provider,
        providerTrackId: providerTrackId,
        title: title,
        artist: artist,
        album: album,
        artworkUrl: artworkUrl,
        durationSeconds: durationSeconds,
        explicit: explicit,
        quality: quality ?? this.quality,
        localPath: localPath ?? this.localPath,
      );
}
