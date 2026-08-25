import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import '../../services/backend_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController url;
  late final TextEditingController token;

  @override
  void initState() {
    super.initState();
    final config = ref.read(backendConfigProvider);
    url = TextEditingController(text: config.baseUrl);
    token = TextEditingController(text: config.token);
  }

  @override
  void dispose() {
    url.dispose();
    token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      const SliverAppBar.large(title: Text('Settings')),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
        sliver: SliverList.list(
          children: [
            Text(
              'Windows backend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Android needs the Windows PC address on your trusted local network. Windows can use localhost.',
            ),
            const SizedBox(height: 22),
            TextField(
              controller: url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Backend address',
                hintText: 'http://192.168.1.10:8765',
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: token,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Pairing token'),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () async {
                  await ref
                      .read(backendConfigProvider.notifier)
                      .save(
                        BackendConfig(
                          baseUrl: url.text.trim().replaceAll(
                            RegExp(r'/$'),
                            '',
                          ),
                          token: token.text,
                        ),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backend settings saved.')),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Save connection'),
              ),
            ),
            const SizedBox(height: 46),
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
              'Monochrome browser',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Provider verification and session data stay inside the embedded browser. '
              'Hi Hat never sends browser cookies or verification tokens to the backend.',
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(apiProvider).resetBrowserSession();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Monochrome browser session reset.'),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('The provider browser helper is unavailable.'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset browser session'),
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
}
