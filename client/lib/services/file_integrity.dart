import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// Hashes large audio files away from Flutter's UI isolate.
Future<String> sha256File(File file) => Isolate.run(
  () async => (await sha256.bind(File(file.path).openRead()).first).toString(),
);
