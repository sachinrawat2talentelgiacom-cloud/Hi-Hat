import 'package:flutter/material.dart';

abstract final class HiHatColors {
  static const signal = Color(0xFFB7FF3C);
  static const chamber = Color(0xFF111311);
  static const chamberRaised = Color(0xFF191C19);
  static const mineral = Color(0xFFE8ECE6);
  static const trace = Color(0xFF90988F);
  static const aluminum = Color(0xFFC9CFCA);
}

abstract final class HiHatTheme {
  static ThemeData get dark => _base(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: HiHatColors.signal,
      onPrimary: Color(0xFF182100),
      secondary: HiHatColors.aluminum,
      onSecondary: Color(0xFF202421),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: HiHatColors.chamber,
      onSurface: HiHatColors.mineral,
      surfaceContainerLow: Color(0xFF151815),
      surfaceContainer: HiHatColors.chamberRaised,
      surfaceContainerHigh: Color(0xFF212521),
      outline: Color(0xFF626962),
      outlineVariant: Color(0xFF303530),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: HiHatColors.mineral,
      onInverseSurface: HiHatColors.chamber,
      inversePrimary: Color(0xFF456900),
    ),
  );

  static ThemeData get light => _base(
    const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF426800),
      onPrimary: Colors.white,
      secondary: Color(0xFF52604D),
      onSecondary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: Color(0xFFF7FAF5),
      onSurface: Color(0xFF191D18),
      surfaceContainerLow: Color(0xFFF0F3ED),
      surfaceContainer: Color(0xFFE9EDE6),
      surfaceContainerHigh: Color(0xFFE2E6DE),
      outline: Color(0xFF747A71),
      outlineVariant: Color(0xFFC4C9C0),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF2E312D),
      onInverseSurface: Color(0xFFF0F1EC),
      inversePrimary: HiHatColors.signal,
    ),
  );

  static ThemeData _base(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 54,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.6,
      ),
      displayMedium: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.1,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 17, height: 1.45),
      bodyMedium: TextStyle(fontSize: 15, height: 1.42),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      minWidth: 88,
      minExtendedWidth: 184,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.outlineVariant,
      thumbColor: scheme.primary,
      trackHeight: 2,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );
}
