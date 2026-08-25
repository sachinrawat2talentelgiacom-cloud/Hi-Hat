import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool browserDebugVisible = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((preferences) {
      if (!mounted) return;
      setState(() {
        browserDebugVisible =
            preferences.getBool('providerBrowserDebugVisible') ?? false;
      });
    });
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      const SliverAppBar.large(title: Text('Settings')),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
        sliver: SliverList.list(
          children: [
            Text('Playback', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.high_quality_outlined),
              title: Text('Preferred quality'),
              subtitle: Text('Highest verified lossless'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.speaker_outlined),
              title: Text('Output path'),
              subtitle: Text('System mixed · exclusive output when confirmed'),
            ),
            const SizedBox(height: 34),
            Text(
              'Provider browser',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Provider verification and session data stay inside the app’s platform WebView. '
              'Hi Hat never exports cookies or verification tokens.',
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show provider browser while acquiring'),
              subtitle: const Text(
                'Diagnostic setting. Verification still appears whenever it is required.',
              ),
              value: browserDebugVisible,
              onChanged: (value) async {
                final preferences = await SharedPreferences.getInstance();
                await preferences.setBool('providerBrowserDebugVisible', value);
                if (mounted) setState(() => browserDebugVisible = value);
              },
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _resetProviderSession,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset provider session'),
              ),
            ),
            const SizedBox(height: 34),
            Text('Use boundary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text(
              'Hi Hat does not bypass authentication, DRM, paywalls, CAPTCHAs, or access controls. '
              'Acquire only content you are permitted to download.',
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _resetProviderSession() async {
    try {
      await CookieManager.instance().deleteAllCookies();
      try {
        await WebStorageManager.instance().deleteAllData();
      } on UnimplementedError {
        // Cookie reset remains available if platform storage clearing is absent.
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider browser session reset.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The provider session could not be reset.'),
        ),
      );
    }
  }
}
