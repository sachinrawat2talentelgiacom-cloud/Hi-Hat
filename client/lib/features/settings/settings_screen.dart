import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../diagnostics/browser_acquisition_log.dart';
import '../../services/library_folder_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool browserDebugVisible = false;
  String? libraryFolder;
  bool choosingFolder = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((preferences) async {
      final folder = await ref
          .read(libraryFolderServiceProvider)
          .configurationLabel();
      if (!mounted) return;
      setState(() {
        browserDebugVisible =
            preferences.getBool('providerBrowserDebugVisible') ?? false;
        libraryFolder = folder;
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
            Text('Library', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Music folder'),
              subtitle: Text(
                libraryFolder ??
                    'Choose where downloaded tracks should be stored',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: choosingFolder
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: choosingFolder ? null : _chooseLibraryFolder,
            ),
            const SizedBox(height: 8),
            Text(
              libraryFolder == null
                  ? 'Hi Hat will ask before your first download.'
                  : 'Downloads are organized as Artist / Album / Track.flac. Library scans this folder for existing FLAC files.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 34),
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
              title: const Text('Browser debug mode'),
              subtitle: const Text(
                'Keep the provider browser visible and interactive, prevent automatic closing, and record a detailed acquisition log.',
              ),
              value: browserDebugVisible,
              onChanged: (value) async {
                final preferences = await SharedPreferences.getInstance();
                await preferences.setBool(
                  providerBrowserDebugPreferenceKey,
                  value,
                );
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

  Future<void> _chooseLibraryFolder() async {
    setState(() => choosingFolder = true);
    try {
      final folders = ref.read(libraryFolderServiceProvider);
      final selected = await folders.chooseFolder();
      if (selected == null || !mounted) return;
      setState(() => libraryFolder = selected);
      final result = await folders.scanConfiguredFolder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.found == 0
                ? 'Music folder saved. New downloads will appear here.'
                : 'Music folder saved. Found ${result.found} FLAC ${result.found == 1 ? 'file' : 'files'}.',
          ),
        ),
      );
    } on FileSystemException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hi Hat cannot write to that folder. Choose another one.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => choosingFolder = false);
    }
  }
}
