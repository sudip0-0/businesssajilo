import 'package:flutter/material.dart';

/// Corporate web typography per Design.md: Inter with tabular figures for data.
///
/// Uses the bundled `Inter` family from `assets/fonts/` (see pubspec.yaml).
abstract final class WebTypography {
  static const String fontFamily = 'Inter';

  static TextStyle _inter({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
    List<FontFeature>? fontFeatures,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: const ['Noto Sans Devanagari'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontFeatures: fontFeatures,
    );
  }

  static TextTheme textTheme(ColorScheme scheme) {
    final base = ThemeData(fontFamily: fontFamily).textTheme;
    return base.copyWith(
      displayLarge: _inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.64,
        color: scheme.onSurface,
      ),
      displayMedium: _inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
        letterSpacing: -0.24,
        color: scheme.onSurface,
      ),
      headlineSmall: _inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: scheme.onSurface,
      ),
      titleLarge: _inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: _inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      bodyLarge: _inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: scheme.onSurface.withValues(alpha: 0.9),
      ),
      bodyMedium: _inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        color: scheme.onSurface.withValues(alpha: 0.85),
      ),
      labelLarge: _inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: 0.6,
      ),
      labelSmall: _inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.27,
        letterSpacing: 0.55,
        color: scheme.onSurface.withValues(alpha: 0.65),
      ),
    );
  }

  static TextStyle monoData(BuildContext context, {double? fontSize}) {
    return _inter(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle metricValue(BuildContext context) {
    return _inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.33,
      letterSpacing: -0.24,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
