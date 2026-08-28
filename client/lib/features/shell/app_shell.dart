import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/download_service.dart';
import '../../services/user_data_store.dart';
import '../../widgets/app_widgets.dart';
import '../browser_acquisition/acquisition_dock.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../player/player_panel.dart';
import '../player/song_actions.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int selected = 0;

  final pages = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  String _breadcrumbTitle() {
    return switch (selected) {
      0 => 'Home',
      1 => 'Search',
      2 => 'Songs',
      3 => 'Settings',
      _ => 'Home',
    };
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadServiceProvider);
    final activeDownloads = downloads.activeTransfers;
    final playlists = ref.watch(playlistProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;

        if (isDesktop) {
          return Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Full-Height Left Navigation Sidebar
                      _buildSidebar(context, playlists),
                      // Main Content & Docked Right Player
                      Expanded(
                        child: Column(
                          children: [
                            // Top Header Bar
                            _buildTopHeader(context, activeDownloads.length),
                            // Page Content
                            Expanded(
                              child: KeyedSubtree(
                                key: ValueKey(selected),
                                child: pages[selected],
                              ),
                            ),
                            // Bottom Player Bar docked ONLY inside the right column!
                            const MiniPlayer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const AcquisitionDock(),
                ],
              ),
            ),
          );
        }

        // Tablet & Mobile layout
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopHeader(context, activeDownloads.length),
                    Expanded(
                      child: KeyedSubtree(
                        key: ValueKey(selected),
                        child: pages[selected],
                      ),
                    ),
                  ],
                ),
                const AcquisitionDock(),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (value) =>
                    setState(() => selected = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search_rounded),
                    label: 'Search',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.graphic_eq_rounded),
                    label: 'Songs',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, int activeDownloadCount) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0D11),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E202B), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb Navigation on left
          Text(
            _breadcrumbTitle(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          // Right Action Icons
          IconButton(
            tooltip: 'Settings',
            onPressed: () => setState(() => selected = 3),
            icon: Icon(
              Icons.settings_outlined,
              size: 21,
              color: selected == 3 ? HiHatColors.coral : HiHatColors.trace,
            ),
          ),
          const SizedBox(width: 4),
          // Downloads / Notification bell
          IconButton(
            tooltip: activeDownloadCount > 0
                ? '$activeDownloadCount active downloads'
                : 'Downloads',
            onPressed: () {
              if (activeDownloadCount > 0) {
                final first = ref
                    .read(downloadServiceProvider)
                    .activeTransfers
                    .firstOrNull;
                if (first != null) {
                  ref
                      .read(downloadServiceProvider.notifier)
                      .focus(first.trackId);
                }
              }
            },
            icon: Badge(
              isLabelVisible: activeDownloadCount > 0,
              backgroundColor: HiHatColors.coral,
              smallSize: 8,
              child: const Icon(
                Icons.notifications_none_outlined,
                size: 21,
                color: HiHatColors.trace,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Avatar / Audiophile Profile
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1F222E),
              border: Border.all(
                color: HiHatColors.coral.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, PlaylistState playlists) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0D11),
        border: Border(
          right: BorderSide(color: Color(0xFF1E202B), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo at top
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 22, 22, 26),
            child: SoundwaveLogo(title: 'Hi Hat', fontSize: 20),
          ),

          // Primary Navigation Links (Only real features)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  icon: Icons.search_rounded,
                  selectedIcon: Icons.search_rounded,
                  label: 'Search',
                  index: 1,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  icon: Icons.graphic_eq_rounded,
                  selectedIcon: Icons.graphic_eq_rounded,
                  label: 'Songs',
                  index: 2,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  icon: Icons.tune_rounded,
                  selectedIcon: Icons.tune_rounded,
                  label: 'Settings',
                  index: 3,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // "Your Library" section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 18,
                      color: HiHatColors.trace,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Your Library',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: HiHatColors.trace,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  iconSize: 18,
                  tooltip: 'Create playlist',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.add, color: HiHatColors.trace),
                  onPressed: () async {
                    final name =
                        await askPlaylistName(context, 'Create playlist');
                    if (name != null && name.trim().isNotEmpty) {
                      final error = await ref
                          .read(playlistProvider.notifier)
                          .create(name.trim());
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(error)));
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Actual User Playlists from Database (Top-aligned compact items)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (playlists.playlists.isEmpty)
                  _buildSidebarActionItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Create playlist',
                    onTap: () async {
                      final name = await askPlaylistName(
                        context,
                        'Create playlist',
                      );
                      if (name != null && name.trim().isNotEmpty) {
                        final error = await ref
                            .read(playlistProvider.notifier)
                            .create(name.trim());
                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      }
                    },
                  )
                else ...[
                  for (final playlist in playlists.playlists)
                    _buildSidebarActionItem(
                      icon: Icons.playlist_play_rounded,
                      label: playlist.name,
                      onTap: () => setState(() => selected = 2),
                    ),
                  const SizedBox(height: 4),
                  _buildSidebarActionItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Create playlist',
                    onTap: () async {
                      final name = await askPlaylistName(
                        context,
                        'Create playlist',
                      );
                      if (name != null && name.trim().isNotEmpty) {
                        final error = await ref
                            .read(playlistProvider.notifier)
                            .create(name.trim());
                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          // Bottom Left Status Pill
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF151720),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF262834),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'English',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: HiHatColors.trace,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: HiHatColors.trace,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = selected == index;

    return Material(
      color: isSelected ? const Color(0xFF171922) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => selected = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected ? HiHatColors.coral : HiHatColors.trace,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : HiHatColors.trace,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

