class AudioQuality {
  const AudioQuality({
    this.codec,
    this.lossless = false,
    this.bitDepth,
    this.sampleRate,
    this.channels,
    this.bitrate,
    this.label,
    this.audioModes = const [],
  });

  final String? codec;
  final bool lossless;
  final int? bitDepth;
  final int? sampleRate;
  final int? channels;
  final int? bitrate;
  final String? label;
  final List<String> audioModes;

  factory AudioQuality.fromJson(Map<String, dynamic>? json) => json == null
      ? const AudioQuality()
      : AudioQuality(
          codec: json['codec'] as String?,
          lossless: json['lossless'] as bool? ?? false,
          bitDepth: json['bit_depth'] as int?,
          sampleRate: json['sample_rate'] as int?,
          channels: json['channels'] as int?,
          bitrate: json['bitrate'] as int?,
          label: json['label'] as String?,
          audioModes:
              (json['audio_modes'] as List?)
                  ?.map((e) => e.toString())
                  .toList(growable: false) ??
              const [],
        );

  String get display {
    final parts = <String>[];
    if (codec != null && codec!.isNotEmpty) {
      parts.add(codec!);
    } else if (label != null && label!.isNotEmpty) {
      final cleanLabel = label!.replaceAll('_', ' ');
      parts.add(_titleCase(cleanLabel));
    } else if (lossless) {
      parts.add('Lossless');
    } else {
      parts.add('Quality pending');
    }

    if (bitDepth != null && bitDepth! > 0) parts.add('$bitDepth-bit');
    if (sampleRate != null && sampleRate! > 0) {
      final khz = sampleRate! / 1000;
      parts.add(
        '${khz == khz.roundToDouble() ? khz.round() : khz.toStringAsFixed(1)} kHz',
      );
    }
    return parts.join(' · ');
  }

  String? get channelsDisplay {
    if (channels == null || channels! <= 0) return null;
    return switch (channels) {
      1 => 'Mono (1 ch)',
      2 => 'Stereo (2 ch)',
      6 => '5.1 Surround (6 ch)',
      8 => '7.1 Surround (8 ch)',
      _ => '$channels channels',
    };
  }

  String? get bitrateDisplay {
    if (bitrate == null || bitrate! <= 0) return null;
    final kbps = (bitrate! / 1000).round();
    return '$kbps kbps';
  }

  static String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          if (word.toUpperCase() == 'HI-RES' || word.toUpperCase() == 'FLAC') {
            return word.toUpperCase();
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
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
    this.year,
    this.trackNumber,
    this.discNumber,
    this.genre,
    this.bpm,
    this.key,
    this.isrc,
    this.copyright,
    this.replayGain,
    this.peak,
    this.fileSize,
    this.version,
    this.vibrantColor,
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
  final String? year;
  final int? trackNumber;
  final int? discNumber;
  final String? genre;
  final int? bpm;
  final String? key;
  final String? isrc;
  final String? copyright;
  final double? replayGain;
  final double? peak;
  final int? fileSize;
  final String? version;
  final String? vibrantColor;

  bool get isLocal => localPath != null;

  String get formattedDuration {
    if (durationSeconds == null || durationSeconds! <= 0) return '--:--';
    final totalSeconds = durationSeconds!.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final hours = minutes ~/ 60;
    if (hours > 0) {
      final remMinutes = minutes % 60;
      return '$hours:${remMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String? get formattedTrackNumber {
    if (trackNumber == null || trackNumber! <= 0) return null;
    if (discNumber != null && discNumber! > 1) {
      return 'Disc $discNumber, Track $trackNumber';
    }
    return 'Track $trackNumber';
  }

  String? get formattedFileSize {
    if (fileSize == null || fileSize! <= 0) return null;
    final mb = fileSize! / (1024 * 1024);
    if (mb >= 1.0) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = (fileSize! / 1024).round();
    return '$kb KB';
  }

  String? get tempoDisplay => bpm != null && bpm! > 0 ? '$bpm BPM' : null;

  String? get musicalKeyDisplay => key != null && key!.isNotEmpty ? key : null;

  String? get albumWithYear {
    if (album == null || album!.isEmpty) return null;
    if (year != null && year!.isNotEmpty) {
      return '$album ($year)';
    }
    return album;
  }

  String get displayTitle {
    if (version != null &&
        version!.isNotEmpty &&
        !title.toLowerCase().contains(version!.toLowerCase())) {
      return '$title ($version)';
    }
    return title;
  }

  String? get highResArtworkUrl {
    if (artworkUrl == null) return null;
    if (artworkUrl!.contains('640x640.jpg')) {
      return artworkUrl!.replaceFirst('640x640.jpg', '1280x1280.jpg');
    }
    return artworkUrl;
  }

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
    year: json['year'] as String?,
    trackNumber: json['track_number'] as int?,
    discNumber: json['disc_number'] as int?,
    genre: json['genre'] as String?,
    bpm: json['bpm'] as int?,
    key: json['key'] as String?,
    isrc: json['isrc'] as String?,
    copyright: json['copyright'] as String?,
    replayGain: (json['replay_gain'] as num?)?.toDouble(),
    peak: (json['peak'] as num?)?.toDouble(),
    fileSize: json['file_size'] as int?,
    version: json['version'] as String?,
    vibrantColor: json['vibrant_color'] as String?,
    localPath: json['local_path'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider,
    'provider_track_id': providerTrackId,
    'title': title,
    'artist': artist,
    'album': album,
    'artwork_url': artworkUrl,
    'duration_seconds': durationSeconds,
    'explicit': explicit,
    'local_path': localPath,
    'year': year,
    'track_number': trackNumber,
    'disc_number': discNumber,
    'genre': genre,
    'bpm': bpm,
    'key': key,
    'isrc': isrc,
    'copyright': copyright,
    'replay_gain': replayGain,
    'peak': peak,
    'file_size': fileSize,
    'version': version,
    'vibrant_color': vibrantColor,
    'available_quality': {
      'codec': quality.codec,
      'lossless': quality.lossless,
      'bit_depth': quality.bitDepth,
      'sample_rate': quality.sampleRate,
      'channels': quality.channels,
      'bitrate': quality.bitrate,
      'label': quality.label,
      'audio_modes': quality.audioModes,
    },
  };

  TrackSummary copyWith({
    String? localPath,
    AudioQuality? quality,
    String? artworkUrl,
    String? year,
    int? trackNumber,
    int? discNumber,
    String? genre,
    int? bpm,
    String? key,
    String? isrc,
    String? copyright,
    double? replayGain,
    double? peak,
    int? fileSize,
    String? version,
    String? vibrantColor,
  }) => TrackSummary(
    id: id,
    provider: provider,
    providerTrackId: providerTrackId,
    title: title,
    artist: artist,
    album: album,
    artworkUrl: artworkUrl ?? this.artworkUrl,
    durationSeconds: durationSeconds,
    explicit: explicit,
    quality: quality ?? this.quality,
    localPath: localPath ?? this.localPath,
    year: year ?? this.year,
    trackNumber: trackNumber ?? this.trackNumber,
    discNumber: discNumber ?? this.discNumber,
    genre: genre ?? this.genre,
    bpm: bpm ?? this.bpm,
    key: key ?? this.key,
    isrc: isrc ?? this.isrc,
    copyright: copyright ?? this.copyright,
    replayGain: replayGain ?? this.replayGain,
    peak: peak ?? this.peak,
    fileSize: fileSize ?? this.fileSize,
    version: version ?? this.version,
    vibrantColor: vibrantColor ?? this.vibrantColor,
  );
}
