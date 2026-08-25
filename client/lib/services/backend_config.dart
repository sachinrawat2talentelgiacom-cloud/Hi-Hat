import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendConfig {
  const BackendConfig({required this.baseUrl, required this.token});
  final String baseUrl;
  final String token;

  BackendConfig copyWith({String? baseUrl, String? token}) => BackendConfig(
    baseUrl: baseUrl ?? this.baseUrl,
    token: token ?? this.token,
  );
}

class BackendConfigNotifier extends StateNotifier<BackendConfig> {
  static const launcherToken = String.fromEnvironment('HI_HAT_API_TOKEN');

  BackendConfigNotifier()
    : super(
        const BackendConfig(
          baseUrl: 'http://127.0.0.1:8765',
          token: 'development-only-change-me',
        ),
      ) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = BackendConfig(
      baseUrl: prefs.getString('backend_url') ?? state.baseUrl,
      token: launcherToken.isNotEmpty
          ? launcherToken
          : prefs.getString('backend_token') ?? state.token,
    );
  }

  Future<void> save(BackendConfig value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_url', value.baseUrl);
    await prefs.setString('backend_token', value.token);
    state = value;
  }
}

final backendConfigProvider =
    StateNotifierProvider<BackendConfigNotifier, BackendConfig>(
      (ref) => BackendConfigNotifier(),
    );
