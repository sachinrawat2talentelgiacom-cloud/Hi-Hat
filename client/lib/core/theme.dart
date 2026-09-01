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
  // Brand expression uses the same green accent as product state.
  static const brandDark = Color(0xFF141413);
  static const brandLight = Color(0xFFFAF9F5);
  static const brandMid = Color(0xFFB0AEA5);
  static const brandLightGray = Color(0xFFE8E6DC);
  static const brandBlue = Color(0xFF6A9BCC);
  static const brandGreen = Color(0xFF788C5D);

  // Product truth. Signal is reserved for live, verified and selected states.
  static const signal = Color(0xFFB7FF3C);
  static const onSignal = Color(0xFF182100);
  static const coral = signal;
  static const coralLight = Color(0xFFD0FF84);
  static const coralDark = Color(0xFF86C900);
  static const chamber = Color(0xFF111311);
  static const chamberSunken = Color(0xFF0C0E0C);
  static const chamberRaised = Color(0xFF191C19);
  static const mineral = Color(0xFFE8ECE6);
  static const trace = Color(0xFFAEB6AC);
  static const aluminum = Color(0xFFC9CFCA);
  static const tape = Color(0xFF212521);
  static const cue = Color(0xFFD0FF84);
  static const cardBorder = Color(0xFF303530);
  static const cardHover = Color(0xFF212521);
}

abstract final class HiHatTheme {
  static ThemeData get dark => _base(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: HiHatColors.signal,
      onPrimary: HiHatColors.onSignal,
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
      inversePrimary: HiHatColors.signal,
    ),
  );

  static ThemeData get light => _base(
    const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF426800),
      onPrimary: Colors.white,
      secondary: Color(0xFF59634F),
      onSecondary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: Color(0xFFF7FAF5),
      onSurface: Color(0xFF191D18),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFF0F3ED),
      surfaceContainer: Color(0xFFE9EDE6),
      surfaceContainerHigh: Color(0xFFE2E6DE),
      surfaceContainerHighest: Color(0xFFDCE0D9),
      outline: Color(0xFF747A71),
      outlineVariant: Color(0xFFC4C9C0),
      shadow: Color(0xFF191D18),
      scrim: Color(0xFF191D18),
      inverseSurface: Color(0xFF2E312D),
      onInverseSurface: Color(0xFFF0F3ED),
      inversePrimary: HiHatColors.signal,
    ),
  );

  static ThemeData _base(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: const [HiHatTokens.standard],
    focusColor: scheme.primary.withValues(alpha: .24),
    hoverColor: Colors.white.withValues(alpha: .04),
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: scheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: scheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: scheme.onSurface),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.42,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: scheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: scheme.onSurfaceVariant,
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
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(48, 48),
        shape: const StadiumBorder(),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.7)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        foregroundColor: scheme.onSurface,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
      thickness: 1,
      space: 1,
    ),
  );
}
