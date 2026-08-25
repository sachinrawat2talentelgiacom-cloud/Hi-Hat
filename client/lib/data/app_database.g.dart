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
    fileSize,
    downloadedAt,
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
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
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
  final int fileSize;
  final DateTime downloadedAt;
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
    required this.fileSize,
    required this.downloadedAt,
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
    map['file_size'] = Variable<int>(fileSize);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
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
      fileSize: Value(fileSize),
      downloadedAt: Value(downloadedAt),
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
      fileSize: serializer.fromJson<int>(json['fileSize']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
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
      'fileSize': serializer.toJson<int>(fileSize),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
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
    int? fileSize,
    DateTime? downloadedAt,
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
    fileSize: fileSize ?? this.fileSize,
    downloadedAt: downloadedAt ?? this.downloadedAt,
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
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
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
          ..write('fileSize: $fileSize, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
    fileSize,
    downloadedAt,
  );
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
          other.fileSize == this.fileSize &&
          other.downloadedAt == this.downloadedAt);
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
  final Value<int> fileSize;
  final Value<DateTime> downloadedAt;
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
    this.fileSize = const Value.absent(),
    this.downloadedAt = const Value.absent(),
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
    required int fileSize,
    this.downloadedAt = const Value.absent(),
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
    Expression<int>? fileSize,
    Expression<DateTime>? downloadedAt,
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
      if (fileSize != null) 'file_size': fileSize,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
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
    Value<int>? fileSize,
    Value<DateTime>? downloadedAt,
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
      fileSize: fileSize ?? this.fileSize,
      downloadedAt: downloadedAt ?? this.downloadedAt,
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
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
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
          ..write('fileSize: $fileSize, ')
          ..write('downloadedAt: $downloadedAt, ')
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
  required int fileSize,
  Value<DateTime> downloadedAt,
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
  Value<int> fileSize,
  Value<DateTime> downloadedAt,
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

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
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

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
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

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
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
                Value<int> fileSize = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
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
                fileSize: fileSize,
                downloadedAt: downloadedAt,
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
                required int fileSize,
                Value<DateTime> downloadedAt = const Value.absent(),
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
                fileSize: fileSize,
                downloadedAt: downloadedAt,
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
