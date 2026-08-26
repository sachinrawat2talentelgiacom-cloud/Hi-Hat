// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerTrackIdMeta = const VerificationMeta(
    'providerTrackId',
  );
  @override
  late final GeneratedColumn<String> providerTrackId = GeneratedColumn<String>(
    'provider_track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codecMeta = const VerificationMeta('codec');
  @override
  late final GeneratedColumn<String> codec = GeneratedColumn<String>(
    'codec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bitDepthMeta = const VerificationMeta(
    'bitDepth',
  );
  @override
  late final GeneratedColumn<int> bitDepth = GeneratedColumn<int>(
    'bit_depth',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleRateMeta = const VerificationMeta(
    'sampleRate',
  );
  @override
  late final GeneratedColumn<int> sampleRate = GeneratedColumn<int>(
    'sample_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelsMeta = const VerificationMeta(
    'channels',
  );
  @override
  late final GeneratedColumn<int> channels = GeneratedColumn<int>(
    'channels',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<double> durationSeconds = GeneratedColumn<double>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _validatedAtMeta = const VerificationMeta(
    'validatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> validatedAt = GeneratedColumn<DateTime>(
    'validated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discNumberMeta = const VerificationMeta(
    'discNumber',
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isrcMeta = const VerificationMeta('isrc');
  @override
  late final GeneratedColumn<String> isrc = GeneratedColumn<String>(
    'isrc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _copyrightMeta = const VerificationMeta(
    'copyright',
  );
  @override
  late final GeneratedColumn<String> copyright = GeneratedColumn<String>(
    'copyright',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replayGainMeta = const VerificationMeta(
    'replayGain',
  );
  @override
  late final GeneratedColumn<double> replayGain = GeneratedColumn<double>(
    'replay_gain',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peakMeta = const VerificationMeta('peak');
  @override
  late final GeneratedColumn<double> peak = GeneratedColumn<double>(
    'peak',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioQualityLabelMeta = const VerificationMeta(
    'audioQualityLabel',
  );
  @override
  late final GeneratedColumn<String> audioQualityLabel =
      GeneratedColumn<String>(
        'audio_quality_label',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _vibrantColorMeta = const VerificationMeta(
    'vibrantColor',
  );
  @override
  late final GeneratedColumn<String> vibrantColor = GeneratedColumn<String>(
    'vibrant_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    provider,
    providerTrackId,
    title,
    artist,
    album,
    artworkUrl,
    localPath,
    sha256,
    codec,
    bitDepth,
    sampleRate,
    channels,
    durationSeconds,
    fileSize,
    downloadedAt,
    validatedAt,
    year,
    trackNumber,
    discNumber,
    genre,
    bpm,
    key,
    isrc,
    copyright,
    replayGain,
    peak,
    version,
    audioQualityLabel,
    vibrantColor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Track> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('provider_track_id')) {
      context.handle(
        _providerTrackIdMeta,
        providerTrackId.isAcceptableOrUnknown(
          data['provider_track_id']!,
          _providerTrackIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerTrackIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('codec')) {
      context.handle(
        _codecMeta,
        codec.isAcceptableOrUnknown(data['codec']!, _codecMeta),
      );
    }
    if (data.containsKey('bit_depth')) {
      context.handle(
        _bitDepthMeta,
        bitDepth.isAcceptableOrUnknown(data['bit_depth']!, _bitDepthMeta),
      );
    }
    if (data.containsKey('sample_rate')) {
      context.handle(
        _sampleRateMeta,
        sampleRate.isAcceptableOrUnknown(data['sample_rate']!, _sampleRateMeta),
      );
    }
    if (data.containsKey('channels')) {
      context.handle(
        _channelsMeta,
        channels.isAcceptableOrUnknown(data['channels']!, _channelsMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    if (data.containsKey('validated_at')) {
      context.handle(
        _validatedAtMeta,
        validatedAt.isAcceptableOrUnknown(
          data['validated_at']!,
          _validatedAtMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('disc_number')) {
      context.handle(
        _discNumberMeta,
        discNumber.isAcceptableOrUnknown(data['disc_number']!, _discNumberMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    }
    if (data.containsKey('isrc')) {
      context.handle(
        _isrcMeta,
        isrc.isAcceptableOrUnknown(data['isrc']!, _isrcMeta),
      );
    }
    if (data.containsKey('copyright')) {
      context.handle(
        _copyrightMeta,
        copyright.isAcceptableOrUnknown(data['copyright']!, _copyrightMeta),
      );
    }
    if (data.containsKey('replay_gain')) {
      context.handle(
        _replayGainMeta,
        replayGain.isAcceptableOrUnknown(data['replay_gain']!, _replayGainMeta),
      );
    }
    if (data.containsKey('peak')) {
      context.handle(
        _peakMeta,
        peak.isAcceptableOrUnknown(data['peak']!, _peakMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('audio_quality_label')) {
      context.handle(
        _audioQualityLabelMeta,
        audioQualityLabel.isAcceptableOrUnknown(
          data['audio_quality_label']!,
          _audioQualityLabelMeta,
        ),
      );
    }
    if (data.containsKey('vibrant_color')) {
      context.handle(
        _vibrantColorMeta,
        vibrantColor.isAcceptableOrUnknown(
          data['vibrant_color']!,
          _vibrantColorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerTrackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_track_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      codec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codec'],
      ),
      bitDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bit_depth'],
      ),
      sampleRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_rate'],
      ),
      channels: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channels'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration_seconds'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
      validatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}validated_at'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      ),
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      ),
      isrc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isrc'],
      ),
      copyright: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}copyright'],
      ),
      replayGain: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}replay_gain'],
      ),
      peak: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peak'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      audioQualityLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_quality_label'],
      ),
      vibrantColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vibrant_color'],
      ),
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final String id;
  final String provider;
  final String providerTrackId;
  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  final String localPath;
  final String sha256;
  final String? codec;
  final int? bitDepth;
  final int? sampleRate;
  final int? channels;
  final double? durationSeconds;
  final int fileSize;
  final DateTime downloadedAt;
  final DateTime validatedAt;
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
  final String? version;
  final String? audioQualityLabel;
  final String? vibrantColor;
  const Track({
    required this.id,
    required this.provider,
    required this.providerTrackId,
    required this.title,
    required this.artist,
    this.album,
    this.artworkUrl,
    required this.localPath,
    required this.sha256,
    this.codec,
    this.bitDepth,
    this.sampleRate,
    this.channels,
    this.durationSeconds,
    required this.fileSize,
    required this.downloadedAt,
    required this.validatedAt,
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
    this.version,
    this.audioQualityLabel,
    this.vibrantColor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider'] = Variable<String>(provider);
    map['provider_track_id'] = Variable<String>(providerTrackId);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    map['local_path'] = Variable<String>(localPath);
    map['sha256'] = Variable<String>(sha256);
    if (!nullToAbsent || codec != null) {
      map['codec'] = Variable<String>(codec);
    }
    if (!nullToAbsent || bitDepth != null) {
      map['bit_depth'] = Variable<int>(bitDepth);
    }
    if (!nullToAbsent || sampleRate != null) {
      map['sample_rate'] = Variable<int>(sampleRate);
    }
    if (!nullToAbsent || channels != null) {
      map['channels'] = Variable<int>(channels);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<double>(durationSeconds);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    map['validated_at'] = Variable<DateTime>(validatedAt);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || bpm != null) {
      map['bpm'] = Variable<int>(bpm);
    }
    if (!nullToAbsent || key != null) {
      map['key'] = Variable<String>(key);
    }
    if (!nullToAbsent || isrc != null) {
      map['isrc'] = Variable<String>(isrc);
    }
    if (!nullToAbsent || copyright != null) {
      map['copyright'] = Variable<String>(copyright);
    }
    if (!nullToAbsent || replayGain != null) {
      map['replay_gain'] = Variable<double>(replayGain);
    }
    if (!nullToAbsent || peak != null) {
      map['peak'] = Variable<double>(peak);
    }
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    if (!nullToAbsent || audioQualityLabel != null) {
      map['audio_quality_label'] = Variable<String>(audioQualityLabel);
    }
    if (!nullToAbsent || vibrantColor != null) {
      map['vibrant_color'] = Variable<String>(vibrantColor);
    }
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      provider: Value(provider),
      providerTrackId: Value(providerTrackId),
      title: Value(title),
      artist: Value(artist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      localPath: Value(localPath),
      sha256: Value(sha256),
      codec: codec == null && nullToAbsent
          ? const Value.absent()
          : Value(codec),
      bitDepth: bitDepth == null && nullToAbsent
          ? const Value.absent()
          : Value(bitDepth),
      sampleRate: sampleRate == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleRate),
      channels: channels == null && nullToAbsent
          ? const Value.absent()
          : Value(channels),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      fileSize: Value(fileSize),
      downloadedAt: Value(downloadedAt),
      validatedAt: Value(validatedAt),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      bpm: bpm == null && nullToAbsent ? const Value.absent() : Value(bpm),
      key: key == null && nullToAbsent ? const Value.absent() : Value(key),
      isrc: isrc == null && nullToAbsent ? const Value.absent() : Value(isrc),
      copyright: copyright == null && nullToAbsent
          ? const Value.absent()
          : Value(copyright),
      replayGain: replayGain == null && nullToAbsent
          ? const Value.absent()
          : Value(replayGain),
      peak: peak == null && nullToAbsent ? const Value.absent() : Value(peak),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      audioQualityLabel: audioQualityLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(audioQualityLabel),
      vibrantColor: vibrantColor == null && nullToAbsent
          ? const Value.absent()
          : Value(vibrantColor),
    );
  }

  factory Track.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<String>(json['id']),
      provider: serializer.fromJson<String>(json['provider']),
      providerTrackId: serializer.fromJson<String>(json['providerTrackId']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      localPath: serializer.fromJson<String>(json['localPath']),
      sha256: serializer.fromJson<String>(json['sha256']),
      codec: serializer.fromJson<String?>(json['codec']),
      bitDepth: serializer.fromJson<int?>(json['bitDepth']),
      sampleRate: serializer.fromJson<int?>(json['sampleRate']),
      channels: serializer.fromJson<int?>(json['channels']),
      durationSeconds: serializer.fromJson<double?>(json['durationSeconds']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      validatedAt: serializer.fromJson<DateTime>(json['validatedAt']),
      year: serializer.fromJson<String?>(json['year']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      genre: serializer.fromJson<String?>(json['genre']),
      bpm: serializer.fromJson<int?>(json['bpm']),
      key: serializer.fromJson<String?>(json['key']),
      isrc: serializer.fromJson<String?>(json['isrc']),
      copyright: serializer.fromJson<String?>(json['copyright']),
      replayGain: serializer.fromJson<double?>(json['replayGain']),
      peak: serializer.fromJson<double?>(json['peak']),
      version: serializer.fromJson<String?>(json['version']),
      audioQualityLabel: serializer.fromJson<String?>(
        json['audioQualityLabel'],
      ),
      vibrantColor: serializer.fromJson<String?>(json['vibrantColor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'provider': serializer.toJson<String>(provider),
      'providerTrackId': serializer.toJson<String>(providerTrackId),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String?>(album),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'localPath': serializer.toJson<String>(localPath),
      'sha256': serializer.toJson<String>(sha256),
      'codec': serializer.toJson<String?>(codec),
      'bitDepth': serializer.toJson<int?>(bitDepth),
      'sampleRate': serializer.toJson<int?>(sampleRate),
      'channels': serializer.toJson<int?>(channels),
      'durationSeconds': serializer.toJson<double?>(durationSeconds),
      'fileSize': serializer.toJson<int>(fileSize),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'validatedAt': serializer.toJson<DateTime>(validatedAt),
      'year': serializer.toJson<String?>(year),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'genre': serializer.toJson<String?>(genre),
      'bpm': serializer.toJson<int?>(bpm),
      'key': serializer.toJson<String?>(key),
      'isrc': serializer.toJson<String?>(isrc),
      'copyright': serializer.toJson<String?>(copyright),
      'replayGain': serializer.toJson<double?>(replayGain),
      'peak': serializer.toJson<double?>(peak),
      'version': serializer.toJson<String?>(version),
      'audioQualityLabel': serializer.toJson<String?>(audioQualityLabel),
      'vibrantColor': serializer.toJson<String?>(vibrantColor),
    };
  }

  Track copyWith({
    String? id,
    String? provider,
    String? providerTrackId,
    String? title,
    String? artist,
    Value<String?> album = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    String? localPath,
    String? sha256,
    Value<String?> codec = const Value.absent(),
    Value<int?> bitDepth = const Value.absent(),
    Value<int?> sampleRate = const Value.absent(),
    Value<int?> channels = const Value.absent(),
    Value<double?> durationSeconds = const Value.absent(),
    int? fileSize,
    DateTime? downloadedAt,
    DateTime? validatedAt,
    Value<String?> year = const Value.absent(),
    Value<int?> trackNumber = const Value.absent(),
    Value<int?> discNumber = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<int?> bpm = const Value.absent(),
    Value<String?> key = const Value.absent(),
    Value<String?> isrc = const Value.absent(),
    Value<String?> copyright = const Value.absent(),
    Value<double?> replayGain = const Value.absent(),
    Value<double?> peak = const Value.absent(),
    Value<String?> version = const Value.absent(),
    Value<String?> audioQualityLabel = const Value.absent(),
    Value<String?> vibrantColor = const Value.absent(),
  }) => Track(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    providerTrackId: providerTrackId ?? this.providerTrackId,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album.present ? album.value : this.album,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    localPath: localPath ?? this.localPath,
    sha256: sha256 ?? this.sha256,
    codec: codec.present ? codec.value : this.codec,
    bitDepth: bitDepth.present ? bitDepth.value : this.bitDepth,
    sampleRate: sampleRate.present ? sampleRate.value : this.sampleRate,
    channels: channels.present ? channels.value : this.channels,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    fileSize: fileSize ?? this.fileSize,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    validatedAt: validatedAt ?? this.validatedAt,
    year: year.present ? year.value : this.year,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    discNumber: discNumber.present ? discNumber.value : this.discNumber,
    genre: genre.present ? genre.value : this.genre,
    bpm: bpm.present ? bpm.value : this.bpm,
    key: key.present ? key.value : this.key,
    isrc: isrc.present ? isrc.value : this.isrc,
    copyright: copyright.present ? copyright.value : this.copyright,
    replayGain: replayGain.present ? replayGain.value : this.replayGain,
    peak: peak.present ? peak.value : this.peak,
    version: version.present ? version.value : this.version,
    audioQualityLabel: audioQualityLabel.present
        ? audioQualityLabel.value
        : this.audioQualityLabel,
    vibrantColor: vibrantColor.present ? vibrantColor.value : this.vibrantColor,
  );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      providerTrackId: data.providerTrackId.present
          ? data.providerTrackId.value
          : this.providerTrackId,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      codec: data.codec.present ? data.codec.value : this.codec,
      bitDepth: data.bitDepth.present ? data.bitDepth.value : this.bitDepth,
      sampleRate: data.sampleRate.present
          ? data.sampleRate.value
          : this.sampleRate,
      channels: data.channels.present ? data.channels.value : this.channels,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      validatedAt: data.validatedAt.present
          ? data.validatedAt.value
          : this.validatedAt,
      year: data.year.present ? data.year.value : this.year,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      genre: data.genre.present ? data.genre.value : this.genre,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      key: data.key.present ? data.key.value : this.key,
      isrc: data.isrc.present ? data.isrc.value : this.isrc,
      copyright: data.copyright.present ? data.copyright.value : this.copyright,
      replayGain: data.replayGain.present
          ? data.replayGain.value
          : this.replayGain,
      peak: data.peak.present ? data.peak.value : this.peak,
      version: data.version.present ? data.version.value : this.version,
      audioQualityLabel: data.audioQualityLabel.present
          ? data.audioQualityLabel.value
          : this.audioQualityLabel,
      vibrantColor: data.vibrantColor.present
          ? data.vibrantColor.value
          : this.vibrantColor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('providerTrackId: $providerTrackId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('localPath: $localPath, ')
          ..write('sha256: $sha256, ')
          ..write('codec: $codec, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('channels: $channels, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('fileSize: $fileSize, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('validatedAt: $validatedAt, ')
          ..write('year: $year, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('genre: $genre, ')
          ..write('bpm: $bpm, ')
          ..write('key: $key, ')
          ..write('isrc: $isrc, ')
          ..write('copyright: $copyright, ')
          ..write('replayGain: $replayGain, ')
          ..write('peak: $peak, ')
          ..write('version: $version, ')
          ..write('audioQualityLabel: $audioQualityLabel, ')
          ..write('vibrantColor: $vibrantColor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    provider,
    providerTrackId,
    title,
    artist,
    album,
    artworkUrl,
    localPath,
    sha256,
    codec,
    bitDepth,
    sampleRate,
    channels,
    durationSeconds,
    fileSize,
    downloadedAt,
    validatedAt,
    year,
    trackNumber,
    discNumber,
    genre,
    bpm,
    key,
    isrc,
    copyright,
    replayGain,
    peak,
    version,
    audioQualityLabel,
    vibrantColor,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.providerTrackId == this.providerTrackId &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.artworkUrl == this.artworkUrl &&
          other.localPath == this.localPath &&
          other.sha256 == this.sha256 &&
          other.codec == this.codec &&
          other.bitDepth == this.bitDepth &&
          other.sampleRate == this.sampleRate &&
          other.channels == this.channels &&
          other.durationSeconds == this.durationSeconds &&
          other.fileSize == this.fileSize &&
          other.downloadedAt == this.downloadedAt &&
          other.validatedAt == this.validatedAt &&
          other.year == this.year &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.genre == this.genre &&
          other.bpm == this.bpm &&
          other.key == this.key &&
          other.isrc == this.isrc &&
          other.copyright == this.copyright &&
          other.replayGain == this.replayGain &&
          other.peak == this.peak &&
          other.version == this.version &&
          other.audioQualityLabel == this.audioQualityLabel &&
          other.vibrantColor == this.vibrantColor);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<String> id;
  final Value<String> provider;
  final Value<String> providerTrackId;
  final Value<String> title;
  final Value<String> artist;
  final Value<String?> album;
  final Value<String?> artworkUrl;
  final Value<String> localPath;
  final Value<String> sha256;
  final Value<String?> codec;
  final Value<int?> bitDepth;
  final Value<int?> sampleRate;
  final Value<int?> channels;
  final Value<double?> durationSeconds;
  final Value<int> fileSize;
  final Value<DateTime> downloadedAt;
  final Value<DateTime> validatedAt;
  final Value<String?> year;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<String?> genre;
  final Value<int?> bpm;
  final Value<String?> key;
  final Value<String?> isrc;
  final Value<String?> copyright;
  final Value<double?> replayGain;
  final Value<double?> peak;
  final Value<String?> version;
  final Value<String?> audioQualityLabel;
  final Value<String?> vibrantColor;
  final Value<int> rowid;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.providerTrackId = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.codec = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.channels = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.validatedAt = const Value.absent(),
    this.year = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.genre = const Value.absent(),
    this.bpm = const Value.absent(),
    this.key = const Value.absent(),
    this.isrc = const Value.absent(),
    this.copyright = const Value.absent(),
    this.replayGain = const Value.absent(),
    this.peak = const Value.absent(),
    this.version = const Value.absent(),
    this.audioQualityLabel = const Value.absent(),
    this.vibrantColor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String id,
    required String provider,
    required String providerTrackId,
    required String title,
    required String artist,
    this.album = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    required String localPath,
    required String sha256,
    this.codec = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.channels = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required int fileSize,
    this.downloadedAt = const Value.absent(),
    this.validatedAt = const Value.absent(),
    this.year = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.genre = const Value.absent(),
    this.bpm = const Value.absent(),
    this.key = const Value.absent(),
    this.isrc = const Value.absent(),
    this.copyright = const Value.absent(),
    this.replayGain = const Value.absent(),
    this.peak = const Value.absent(),
    this.version = const Value.absent(),
    this.audioQualityLabel = const Value.absent(),
    this.vibrantColor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       provider = Value(provider),
       providerTrackId = Value(providerTrackId),
       title = Value(title),
       artist = Value(artist),
       localPath = Value(localPath),
       sha256 = Value(sha256),
       fileSize = Value(fileSize);
  static Insertable<Track> custom({
    Expression<String>? id,
    Expression<String>? provider,
    Expression<String>? providerTrackId,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? artworkUrl,
    Expression<String>? localPath,
    Expression<String>? sha256,
    Expression<String>? codec,
    Expression<int>? bitDepth,
    Expression<int>? sampleRate,
    Expression<int>? channels,
    Expression<double>? durationSeconds,
    Expression<int>? fileSize,
    Expression<DateTime>? downloadedAt,
    Expression<DateTime>? validatedAt,
    Expression<String>? year,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<String>? genre,
    Expression<int>? bpm,
    Expression<String>? key,
    Expression<String>? isrc,
    Expression<String>? copyright,
    Expression<double>? replayGain,
    Expression<double>? peak,
    Expression<String>? version,
    Expression<String>? audioQualityLabel,
    Expression<String>? vibrantColor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (providerTrackId != null) 'provider_track_id': providerTrackId,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (localPath != null) 'local_path': localPath,
      if (sha256 != null) 'sha256': sha256,
      if (codec != null) 'codec': codec,
      if (bitDepth != null) 'bit_depth': bitDepth,
      if (sampleRate != null) 'sample_rate': sampleRate,
      if (channels != null) 'channels': channels,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (fileSize != null) 'file_size': fileSize,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (validatedAt != null) 'validated_at': validatedAt,
      if (year != null) 'year': year,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (genre != null) 'genre': genre,
      if (bpm != null) 'bpm': bpm,
      if (key != null) 'key': key,
      if (isrc != null) 'isrc': isrc,
      if (copyright != null) 'copyright': copyright,
      if (replayGain != null) 'replay_gain': replayGain,
      if (peak != null) 'peak': peak,
      if (version != null) 'version': version,
      if (audioQualityLabel != null) 'audio_quality_label': audioQualityLabel,
      if (vibrantColor != null) 'vibrant_color': vibrantColor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith({
    Value<String>? id,
    Value<String>? provider,
    Value<String>? providerTrackId,
    Value<String>? title,
    Value<String>? artist,
    Value<String?>? album,
    Value<String?>? artworkUrl,
    Value<String>? localPath,
    Value<String>? sha256,
    Value<String?>? codec,
    Value<int?>? bitDepth,
    Value<int?>? sampleRate,
    Value<int?>? channels,
    Value<double?>? durationSeconds,
    Value<int>? fileSize,
    Value<DateTime>? downloadedAt,
    Value<DateTime>? validatedAt,
    Value<String?>? year,
    Value<int?>? trackNumber,
    Value<int?>? discNumber,
    Value<String?>? genre,
    Value<int?>? bpm,
    Value<String?>? key,
    Value<String?>? isrc,
    Value<String?>? copyright,
    Value<double?>? replayGain,
    Value<double?>? peak,
    Value<String?>? version,
    Value<String?>? audioQualityLabel,
    Value<String?>? vibrantColor,
    Value<int>? rowid,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      providerTrackId: providerTrackId ?? this.providerTrackId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      localPath: localPath ?? this.localPath,
      sha256: sha256 ?? this.sha256,
      codec: codec ?? this.codec,
      bitDepth: bitDepth ?? this.bitDepth,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSize: fileSize ?? this.fileSize,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      validatedAt: validatedAt ?? this.validatedAt,
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
      version: version ?? this.version,
      audioQualityLabel: audioQualityLabel ?? this.audioQualityLabel,
      vibrantColor: vibrantColor ?? this.vibrantColor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerTrackId.present) {
      map['provider_track_id'] = Variable<String>(providerTrackId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (codec.present) {
      map['codec'] = Variable<String>(codec.value);
    }
    if (bitDepth.present) {
      map['bit_depth'] = Variable<int>(bitDepth.value);
    }
    if (sampleRate.present) {
      map['sample_rate'] = Variable<int>(sampleRate.value);
    }
    if (channels.present) {
      map['channels'] = Variable<int>(channels.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<double>(durationSeconds.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (validatedAt.present) {
      map['validated_at'] = Variable<DateTime>(validatedAt.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (isrc.present) {
      map['isrc'] = Variable<String>(isrc.value);
    }
    if (copyright.present) {
      map['copyright'] = Variable<String>(copyright.value);
    }
    if (replayGain.present) {
      map['replay_gain'] = Variable<double>(replayGain.value);
    }
    if (peak.present) {
      map['peak'] = Variable<double>(peak.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (audioQualityLabel.present) {
      map['audio_quality_label'] = Variable<String>(audioQualityLabel.value);
    }
    if (vibrantColor.present) {
      map['vibrant_color'] = Variable<String>(vibrantColor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('providerTrackId: $providerTrackId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('localPath: $localPath, ')
          ..write('sha256: $sha256, ')
          ..write('codec: $codec, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('channels: $channels, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('fileSize: $fileSize, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('validatedAt: $validatedAt, ')
          ..write('year: $year, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('genre: $genre, ')
          ..write('bpm: $bpm, ')
          ..write('key: $key, ')
          ..write('isrc: $isrc, ')
          ..write('copyright: $copyright, ')
          ..write('replayGain: $replayGain, ')
          ..write('peak: $peak, ')
          ..write('version: $version, ')
          ..write('audioQualityLabel: $audioQualityLabel, ')
          ..write('vibrantColor: $vibrantColor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tracks];
}

typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  required String id,
  required String provider,
  required String providerTrackId,
  required String title,
  required String artist,
  Value<String?> album,
  Value<String?> artworkUrl,
  required String localPath,
  required String sha256,
  Value<String?> codec,
  Value<int?> bitDepth,
  Value<int?> sampleRate,
  Value<int?> channels,
  Value<double?> durationSeconds,
  required int fileSize,
  Value<DateTime> downloadedAt,
  Value<DateTime> validatedAt,
  Value<String?> year,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<String?> genre,
  Value<int?> bpm,
  Value<String?> key,
  Value<String?> isrc,
  Value<String?> copyright,
  Value<double?> replayGain,
  Value<double?> peak,
  Value<String?> version,
  Value<String?> audioQualityLabel,
  Value<String?> vibrantColor,
  Value<int> rowid,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<String> id,
  Value<String> provider,
  Value<String> providerTrackId,
  Value<String> title,
  Value<String> artist,
  Value<String?> album,
  Value<String?> artworkUrl,
  Value<String> localPath,
  Value<String> sha256,
  Value<String?> codec,
  Value<int?> bitDepth,
  Value<int?> sampleRate,
  Value<int?> channels,
  Value<double?> durationSeconds,
  Value<int> fileSize,
  Value<DateTime> downloadedAt,
  Value<DateTime> validatedAt,
  Value<String?> year,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<String?> genre,
  Value<int?> bpm,
  Value<String?> key,
  Value<String?> isrc,
  Value<String?> copyright,
  Value<double?> replayGain,
  Value<double?> peak,
  Value<String?> version,
  Value<String?> audioQualityLabel,
  Value<String?> vibrantColor,
  Value<int> rowid,
});

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerTrackId => $composableBuilder(
    column: $table.providerTrackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codec => $composableBuilder(
    column: $table.codec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validatedAt => $composableBuilder(
    column: $table.validatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isrc => $composableBuilder(
    column: $table.isrc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get copyright => $composableBuilder(
    column: $table.copyright,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get replayGain => $composableBuilder(
    column: $table.replayGain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get peak => $composableBuilder(
    column: $table.peak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioQualityLabel => $composableBuilder(
    column: $table.audioQualityLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vibrantColor => $composableBuilder(
    column: $table.vibrantColor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerTrackId => $composableBuilder(
    column: $table.providerTrackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codec => $composableBuilder(
    column: $table.codec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validatedAt => $composableBuilder(
    column: $table.validatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isrc => $composableBuilder(
    column: $table.isrc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get copyright => $composableBuilder(
    column: $table.copyright,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get replayGain => $composableBuilder(
    column: $table.replayGain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get peak => $composableBuilder(
    column: $table.peak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioQualityLabel => $composableBuilder(
    column: $table.audioQualityLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vibrantColor => $composableBuilder(
    column: $table.vibrantColor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get providerTrackId => $composableBuilder(
    column: $table.providerTrackId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get codec =>
      $composableBuilder(column: $table.codec, builder: (column) => column);

  GeneratedColumn<int> get bitDepth =>
      $composableBuilder(column: $table.bitDepth, builder: (column) => column);

  GeneratedColumn<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get channels =>
      $composableBuilder(column: $table.channels, builder: (column) => column);

  GeneratedColumn<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get validatedAt => $composableBuilder(
    column: $table.validatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get isrc =>
      $composableBuilder(column: $table.isrc, builder: (column) => column);

  GeneratedColumn<String> get copyright =>
      $composableBuilder(column: $table.copyright, builder: (column) => column);

  GeneratedColumn<double> get replayGain => $composableBuilder(
    column: $table.replayGain,
    builder: (column) => column,
  );

  GeneratedColumn<double> get peak =>
      $composableBuilder(column: $table.peak, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get audioQualityLabel => $composableBuilder(
    column: $table.audioQualityLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vibrantColor => $composableBuilder(
    column: $table.vibrantColor,
    builder: (column) => column,
  );
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTable,
          Track,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (Track, BaseReferences<_$AppDatabase, $TracksTable, Track>),
          Track,
          PrefetchHooks Function()
        > {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> providerTrackId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String?> codec = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                Value<int?> sampleRate = const Value.absent(),
                Value<int?> channels = const Value.absent(),
                Value<double?> durationSeconds = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<DateTime> validatedAt = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> bpm = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<String?> isrc = const Value.absent(),
                Value<String?> copyright = const Value.absent(),
                Value<double?> replayGain = const Value.absent(),
                Value<double?> peak = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String?> audioQualityLabel = const Value.absent(),
                Value<String?> vibrantColor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                provider: provider,
                providerTrackId: providerTrackId,
                title: title,
                artist: artist,
                album: album,
                artworkUrl: artworkUrl,
                localPath: localPath,
                sha256: sha256,
                codec: codec,
                bitDepth: bitDepth,
                sampleRate: sampleRate,
                channels: channels,
                durationSeconds: durationSeconds,
                fileSize: fileSize,
                downloadedAt: downloadedAt,
                validatedAt: validatedAt,
                year: year,
                trackNumber: trackNumber,
                discNumber: discNumber,
                genre: genre,
                bpm: bpm,
                key: key,
                isrc: isrc,
                copyright: copyright,
                replayGain: replayGain,
                peak: peak,
                version: version,
                audioQualityLabel: audioQualityLabel,
                vibrantColor: vibrantColor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String provider,
                required String providerTrackId,
                required String title,
                required String artist,
                Value<String?> album = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                required String localPath,
                required String sha256,
                Value<String?> codec = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                Value<int?> sampleRate = const Value.absent(),
                Value<int?> channels = const Value.absent(),
                Value<double?> durationSeconds = const Value.absent(),
                required int fileSize,
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<DateTime> validatedAt = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> bpm = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<String?> isrc = const Value.absent(),
                Value<String?> copyright = const Value.absent(),
                Value<double?> replayGain = const Value.absent(),
                Value<double?> peak = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String?> audioQualityLabel = const Value.absent(),
                Value<String?> vibrantColor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                provider: provider,
                providerTrackId: providerTrackId,
                title: title,
                artist: artist,
                album: album,
                artworkUrl: artworkUrl,
                localPath: localPath,
                sha256: sha256,
                codec: codec,
                bitDepth: bitDepth,
                sampleRate: sampleRate,
                channels: channels,
                durationSeconds: durationSeconds,
                fileSize: fileSize,
                downloadedAt: downloadedAt,
                validatedAt: validatedAt,
                year: year,
                trackNumber: trackNumber,
                discNumber: discNumber,
                genre: genre,
                bpm: bpm,
                key: key,
                isrc: isrc,
                copyright: copyright,
                replayGain: replayGain,
                peak: peak,
                version: version,
                audioQualityLabel: audioQualityLabel,
                vibrantColor: vibrantColor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTable,
      Track,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (Track, BaseReferences<_$AppDatabase, $TracksTable, Track>),
      Track,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
}
