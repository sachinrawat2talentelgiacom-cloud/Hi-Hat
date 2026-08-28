import 'package:flutter/material.dart';

@immutable
class HiHatTokens extends ThemeExtension<HiHatTokens> {
  const HiHatTokens({
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusPill,
    required this.controlHeight,
    required this.motionFast,
    required this.motionBase,
  });

  final double spaceXs, spaceSm, spaceMd, spaceLg, spaceXl;
  final double radiusSm, radiusMd, radiusPill, controlHeight;
  final Duration motionFast, motionBase;

  static const standard = HiHatTokens(
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 16,
    spaceLg: 24,
    spaceXl: 40,
    radiusSm: 6,
    radiusMd: 12,
    radiusPill: 999,
    controlHeight: 48,
    motionFast: Duration(milliseconds: 120),
    motionBase: Duration(milliseconds: 220),
  );

  @override
  HiHatTokens copyWith({
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusPill,
    double? controlHeight,
    Duration? motionFast,
    Duration? motionBase,
  }) => HiHatTokens(
    spaceXs: spaceXs ?? this.spaceXs,
    spaceSm: spaceSm ?? this.spaceSm,
    spaceMd: spaceMd ?? this.spaceMd,
    spaceLg: spaceLg ?? this.spaceLg,
    spaceXl: spaceXl ?? this.spaceXl,
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    radiusPill: radiusPill ?? this.radiusPill,
    controlHeight: controlHeight ?? this.controlHeight,
    motionFast: motionFast ?? this.motionFast,
    motionBase: motionBase ?? this.motionBase,
  );

  @override
  HiHatTokens lerp(covariant HiHatTokens? other, double t) {
    if (other == null) return this;
    return HiHatTokens(
      spaceXs: _lerp(spaceXs, other.spaceXs, t),
      spaceSm: _lerp(spaceSm, other.spaceSm, t),
      spaceMd: _lerp(spaceMd, other.spaceMd, t),
      spaceLg: _lerp(spaceLg, other.spaceLg, t),
      spaceXl: _lerp(spaceXl, other.spaceXl, t),
      radiusSm: _lerp(radiusSm, other.radiusSm, t),
      radiusMd: _lerp(radiusMd, other.radiusMd, t),
      radiusPill: _lerp(radiusPill, other.radiusPill, t),
      controlHeight: _lerp(controlHeight, other.controlHeight, t),
      motionFast: Duration(
        milliseconds: _lerp(
          motionFast.inMilliseconds.toDouble(),
          other.motionFast.inMilliseconds.toDouble(),
          t,
        ).round(),
      ),
      motionBase: Duration(
        milliseconds: _lerp(
          motionBase.inMilliseconds.toDouble(),
          other.motionBase.inMilliseconds.toDouble(),
          t,
        ).round(),
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

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
      outline: HiHatColors.trace,
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
    extensions: const [HiHatTokens.standard],
    focusColor: scheme.primary.withValues(alpha: .24),
    hoverColor: scheme.onSurface.withValues(alpha: .06),
    splashFactory: InkSparkle.splashFactory,
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
      height: 68,
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
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.outlineVariant,
      thumbColor: scheme.primary,
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: const StadiumBorder(),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size.square(44)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );
}
