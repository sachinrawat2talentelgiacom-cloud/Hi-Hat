import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/shell/app_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class HiHatApp extends StatelessWidget {
  const HiHatApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Hi Hat',
    navigatorKey: navigatorKey,
    debugShowCheckedModeBanner: false,
    theme: HiHatTheme.light,
    darkTheme: HiHatTheme.dark,
    themeMode: ThemeMode.dark,
    home: const AppShell(),
  );
}
