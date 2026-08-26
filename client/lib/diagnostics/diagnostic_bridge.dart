import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'diagnostic_command_router.dart';
import 'diagnostic_state_store.dart';

class DiagnosticBridge extends ConsumerStatefulWidget {
  const DiagnosticBridge({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<DiagnosticBridge> createState() => _DiagnosticBridgeState();
}

class _DiagnosticBridgeState extends ConsumerState<DiagnosticBridge> {
  static const _channel = MethodChannel('hihat/diagnostics');

  @override
  void initState() {
    super.initState();
    if (kDebugMode) _channel.setMethodCallHandler(_handle);
  }

  Future<String> _handle(MethodCall call) async {
    if (call.method != 'command' || call.arguments is! String) {
      return jsonEncode({'ok': false, 'error': 'INVALID_NATIVE_COMMAND'});
    }
    try {
      final request = jsonDecode(call.arguments as String);
      if (request is! Map) {
        return jsonEncode({'ok': false, 'error': 'INVALID_JSON_REQUEST'});
      }
      final response = await DiagnosticCommandRouter(ref)
          .handle(Map<String, dynamic>.from(request));
      return jsonEncode(response);
    } catch (error, stackTrace) {
      ref.read(diagnosticStateProvider.notifier).error(error.toString());
      debugPrint('Diagnostic command failed: $error\n$stackTrace');
      return jsonEncode({'ok': false, 'error': error.toString()});
    }
  }

  @override
  void dispose() {
    if (kDebugMode) _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
