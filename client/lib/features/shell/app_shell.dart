import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/brand_widgets.dart';
import '../browser_acquisition/acquisition_dock.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../player/player_panel.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int selected = 0;

  static const pages = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  static const destinations = <_Destination>[
    _Destination('Listen', Icons.home_outlined, Icons.home_rounded),
    _Destination('Find', Icons.search_rounded, Icons.search_rounded),
    _Destination('Owned', Icons.album_outlined, Icons.album_rounded),
    _Destination('Setup', Icons.tune_outlined, Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final expanded = width >= 980;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (expanded)
              Row(
                children: [
                  _IdentityRail(
                    selected: selected,
                    onSelected: (value) => setState(() => selected = value),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _CommandHeader(
                          title: destinations[selected].label,
                          onOpenSetup: () => setState(() => selected = 3),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: KeyedSubtree(
                              key: ValueKey(selected),
                              child: pages[selected],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: width >= 1320 ? 440 : 360,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLowest,
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: const PlayerPanel(),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _CommandHeader(
                    title: destinations[selected].label,
                    onOpenSetup: () => setState(() => selected = 3),
                    compact: true,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(selected),
                        child: pages[selected],
                      ),
                    ),
                  ),
                  const MiniPlayer(),
                  NavigationBar(
                    selectedIndex: selected,
                    onDestinationSelected: (value) =>
                        setState(() => selected = value),
                    destinations: [
                      for (final destination in destinations)
                        NavigationDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: destination.label,
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _IdentityRail extends StatelessWidget {
  const _IdentityRail({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: 92,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      border: Border(
        right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: HiHatLockup(compact: true),
        ),
        Container(
          width: 28,
          height: 1,
          color: HiHatColors.brandOrange.withValues(alpha: .65),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            selectedIndex: selected,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: onSelected,
            destinations: [
              for (final destination in _AppShellState.destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 18),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              'HEAR WHAT MATTERS.',
              style: TextStyle(
                color: HiHatColors.brandMid,
                fontSize: 9,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CommandHeader extends StatelessWidget {
  const _CommandHeader({
    required this.title,
    required this.onOpenSetup,
    this.compact = false,
  });

  final String title;
  final VoidCallback onOpenSetup;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 68),
    padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Row(
      children: [
        if (compact) ...[
          const HiHatLockup(compact: true),
          const SizedBox(width: 12),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact) const HiHatEyebrow('Listening instrument'),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const Spacer(),
        DownloadsButton(compact: compact),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Setup and preferences',
          onPressed: onOpenSetup,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    ),
  );
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
