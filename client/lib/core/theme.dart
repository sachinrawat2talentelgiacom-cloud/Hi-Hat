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
  static const signal = Color(0xFFFF5E4D);
  static const coral = Color(0xFFFF5E4D);
  static const coralLight = Color(0xFFFF7A6B);
  static const coralDark = Color(0xFFE54736);
  static const chamber = Color(0xFF0C0D11);
  static const chamberSunken = Color(0xFF090A0D);
  static const chamberRaised = Color(0xFF15171E);
  static const mineral = Color(0xFFF4F5F8);
  static const trace = Color(0xFF8E92A2);
  static const aluminum = Color(0xFFD2D5E0);
  static const tape = Color(0xFF1E202B);
  static const cue = Color(0xFFFF8A7A);
  static const cardBorder = Color(0xFF262834);
  static const cardHover = Color(0xFF1F222D);
}

abstract final class HiHatTheme {
  static ThemeData get dark => _base(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: HiHatColors.coral,
      onPrimary: Colors.white,
      secondary: HiHatColors.coralLight,
      onSecondary: Colors.black,
      error: Color(0xFFFF5252),
      onError: Colors.white,
      surface: HiHatColors.chamber,
      onSurface: HiHatColors.mineral,
      surfaceContainerLowest: HiHatColors.chamberSunken,
      surfaceContainerLow: Color(0xFF111218),
      surfaceContainer: HiHatColors.chamberRaised,
      surfaceContainerHigh: HiHatColors.tape,
      surfaceContainerHighest: Color(0xFF252836),
      outline: HiHatColors.trace,
      outlineVariant: HiHatColors.cardBorder,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: HiHatColors.mineral,
      onInverseSurface: HiHatColors.chamber,
      inversePrimary: Color(0xFFFF7A6B),
    ),
  );

  static ThemeData get light => dark; // MelodyMix theme is dark-first

  static ThemeData _base(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: const [HiHatTokens.standard],
    focusColor: scheme.primary.withValues(alpha: .24),
    hoverColor: Colors.white.withValues(alpha: .04),
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: HiHatColors.mineral,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: HiHatColors.mineral,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: HiHatColors.mineral,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: HiHatColors.mineral,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: HiHatColors.mineral,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: HiHatColors.mineral,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.45,
        color: HiHatColors.mineral,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.42,
        color: HiHatColors.trace,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: HiHatColors.mineral,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: HiHatColors.trace,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: HiHatColors.trace,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.normal,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
          size: 22,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      minWidth: 72,
      minExtendedWidth: 240,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      hintStyle: TextStyle(
        color: scheme.outline.withValues(alpha: 0.8),
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.outlineVariant,
      thumbColor: scheme.primary,
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
        shape: const StadiumBorder(),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.7)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(40),
        foregroundColor: HiHatColors.mineral,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
      thickness: 1,
      space: 1,
    ),
  );
}
