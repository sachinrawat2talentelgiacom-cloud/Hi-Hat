// THESIS: Hi Hat is a calibrated listening chamber, refusing the promotional streaming dashboard.
// OWN-WORLD: absorptive charcoal fields, mineral type, acid-chartreuse signal, machined circular controls.
// STORY: search once, verify the source, save it locally, and return to a durable library.
// FIRST VIEWPORT: compact opens on one monumental search line; expanded windows split ledger and player.
// FORM: acoustic calibration chamber, grounded direction 4, seed 30b4a877.
// FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio_engine.dart';
import '../../core/theme.dart';
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
  final pages = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(audioEngineProvider);
    final tokens = Theme.of(context).extension<HiHatTokens>()!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Widget page() => AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : tokens.motionBase,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey(selected), child: pages[selected]),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth >= 980;
        if (expanded) {
          return Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  Row(
                    children: [
                      NavigationRail(
                        selectedIndex: selected,
                        extended: constraints.maxWidth >= 1260,
                        onDestinationSelected: (value) =>
                            setState(() => selected = value),
                        leading: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 22, 12, 36),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'HI HAT',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home_rounded),
                            label: Text('Home'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.search),
                            label: Text('Search'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.library_music_outlined),
                            label: Text('Library'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.tune),
                            label: Text('Settings'),
                          ),
                        ],
                      ),
                      const VerticalDivider(),
                      Expanded(child: page()),
                    ],
                  ),
                  const AcquisitionDock(),
                ],
              ),
            ),
            bottomNavigationBar: playback.track == null
                ? null
                : const MiniPlayer(),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: page()),
                const AcquisitionDock(),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (playback.track != null) const MiniPlayer(),
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
                    icon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    label: 'Library',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune),
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
}
