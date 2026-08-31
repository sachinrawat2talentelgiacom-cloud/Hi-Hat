import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../core/scroll_behavior.dart';
import '../../diagnostics/browser_acquisition_log.dart';
import '../../services/library_folder_service.dart';
import '../../widgets/brand_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool browserDebugVisible = false;
  String? libraryFolder;
  bool choosingFolder = false;
  final scrollController = SmoothScrollController(debugLabel: 'settings');

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
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 700 ? 16.0 : 28.0;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 48),
          sliver: SliverList.list(
            children: [
              const HiHatEyebrow('System'),
              const SizedBox(height: 8),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Connection, storage, playback, and application identity.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: HiHatColors.trace),
              ),
              const SizedBox(height: 30),

              // Library Section Card
              _buildSectionCard(
                title: 'Library location',
                icon: Icons.folder_outlined,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.folder_open_rounded,
                      color: HiHatColors.coral,
                    ),
                    title: const Text(
                      'Music folder',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      libraryFolder ??
                          'Choose where downloaded tracks should be stored',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: HiHatColors.trace),
                    ),
                    trailing: choosingFolder
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: HiHatColors.coral,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: HiHatColors.trace,
                          ),
                    onTap: choosingFolder ? null : _chooseLibraryFolder,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    libraryFolder == null
                        ? 'Hi Hat will ask before your first download.'
                        : 'Downloads are organized as Artist / Album / Track.flac. Library scans this folder for existing FLAC files.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: HiHatColors.trace,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Playback Section Card
              _buildSectionCard(
                title: 'Playback and output',
                icon: Icons.graphic_eq_rounded,
                children: const [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.high_quality_outlined,
                      color: HiHatColors.coral,
                    ),
                    title: Text(
                      'Preferred quality',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Highest verified supported lossless file',
                      style: TextStyle(color: HiHatColors.trace),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.speaker_outlined,
                      color: HiHatColors.coral,
                    ),
                    title: Text(
                      'Output path',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'System mixed · exclusive output when confirmed',
                      style: TextStyle(color: HiHatColors.trace),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildSectionCard(
                title: 'Connection and provider',
                icon: Icons.shield_outlined,
                children: [
                  const Text(
                    'Provider verification and session data stay inside the app’s platform WebView. '
                    'Hi Hat never exports cookies or verification tokens.',
                    style: TextStyle(color: HiHatColors.trace, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: HiHatColors.coral,
                    title: const Text(
                      'Browser debug mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: const Text(
                      'Keep the provider browser visible and interactive, prevent automatic closing, and record a detailed acquisition log.',
                      style: TextStyle(color: HiHatColors.trace),
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
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _resetProviderSession,
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Reset provider session'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildSectionCard(
                title: 'Appearance and accessibility',
                icon: Icons.contrast_rounded,
                children: const [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.motion_photos_off_outlined,
                      color: HiHatColors.brandBlue,
                    ),
                    title: Text(
                      'System accessibility',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Hi Hat follows text scaling, high contrast, keyboard focus, and reduced-motion preferences.',
                      style: TextStyle(color: HiHatColors.trace),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Use Boundary
              _buildSectionCard(
                title: 'About Hi Hat',
                icon: Icons.lock_outline_rounded,
                children: const [
                  HiHatLockup(),
                  SizedBox(height: 14),
                  Text(
                    'Hear what matters.',
                    style: TextStyle(
                      color: HiHatColors.signal,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Your verified local files remain playable without the provider or server. Hi Hat does not bypass authentication, DRM, paywalls, CAPTCHAs, or access controls.',
                    style: TextStyle(color: HiHatColors.trace, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: HiHatColors.cardBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: HiHatColors.signal),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

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
