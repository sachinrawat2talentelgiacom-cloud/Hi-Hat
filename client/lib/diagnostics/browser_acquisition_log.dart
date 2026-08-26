import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const providerBrowserDebugPreferenceKey = 'providerBrowserDebugVisible';

class BrowserAcquisitionLog {
  BrowserAcquisitionLog({required this.trackId, required this.onEntry});
  final String trackId;
  final ValueChanged<String> onEntry;
  final List<String> entries = <String>[];
  File? _file;
  Future<void> _writeQueue = Future<void>.value();

  String? get path => _file?.path;

  Future<void> start() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      p.join(root.path, 'logs', 'browser-acquisition'),
    );
    await directory.create(recursive: true);
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final safeTrackId = trackId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    _file = File(p.join(directory.path, '$stamp-$safeTrackId.log'));
    await event('SESSION_START', {'trackId': trackId, 'logPath': _file!.path});
  }

  Future<void> event(String event, [Map<String, Object?> fields = const {}]) {
    final line = jsonEncode(<String, Object?>{
      'time': DateTime.now().toUtc().toIso8601String(),
      'event': event,
      ...fields.map((key, value) => MapEntry(key, _redact(value))),
    });
    entries.add(line);
    developer.log(line, name: 'HiHat.BrowserAcquisition');
    debugPrint('[HiHat.BrowserAcquisition] $line');
    onEntry(line);
    final file = _file;
    if (file != null) {
      _writeQueue = _writeQueue.then(
        (_) => file.writeAsString(
          '$line${Platform.lineTerminator}',
          mode: FileMode.append,
          flush: true,
        ),
      );
    }
    return _writeQueue;
  }

  Future<void> close() async {
    await event('SESSION_END');
    await _writeQueue;
  }

  Object? _redact(Object? value) {
    if (value is! String) return value;
    return value
        .replaceAllMapped(
          RegExp(r'(-decryption_key\s+)[0-9a-f]+', caseSensitive: false),
          (match) => '${match.group(1)}<redacted>',
        )
        .replaceAllMapped(
          RegExp(r'''(bearer\s+)[^\s"']+''', caseSensitive: false),
          (match) => '${match.group(1)}<redacted>',
        );
  }
}
