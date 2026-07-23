import 'package:flutter/material.dart';

import 'web_palette.dart';

/// "Digital Ledger" web typography.
///
/// Three bundled voices (see pubspec.yaml):
/// * **Spectral** — editorial serif for display, page titles and metrics.
/// * **Barlow** — the UI workhorse grotesque.
/// * **IBM Plex Mono** — money, identifiers and tabular data.
///
/// Noto Sans Devanagari remains the fallback for Nepali strings.
abstract final class WebTypography {
  static const String fontFamily = 'Barlow';
  static const String serifFamily = 'Spectral';
  static const String monoFamily = 'IBM Plex Mono';

  static const List<String> _fallback = ['Noto Sans Devanagari'];

  static TextStyle _sans({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
    List<FontFeature>? fontFeatures,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: _fallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontFeatures: fontFeatures,
    );
  }

  /// Serif display voice — page titles, hero numbers, the brand wordmark.
  static TextStyle serif({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
    bool italic = false,
  }) {
    return TextStyle(
      fontFamily: serifFamily,
      fontFamilyFallback: _fallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );
  }

  /// Mono voice for money columns, bill numbers and identifiers.
  static TextStyle mono({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: _fallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextTheme textTheme(ColorScheme scheme) {
    final base = ThemeData(fontFamily: fontFamily).textTheme;
    return base.copyWith(
      displayLarge: serif(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      displayMedium: serif(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      headlineSmall: serif(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.22,
        letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
      titleLarge: serif(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        height: 1.28,
        color: scheme.onSurface,
      ),
      titleMedium: _sans(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleSmall: _sans(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      bodyLarge: _sans(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: scheme.onSurface.withValues(alpha: 0.92),
      ),
      bodyMedium: _sans(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: scheme.onSurface.withValues(alpha: 0.88),
      ),
      bodySmall: _sans(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: scheme.onSurface.withValues(alpha: 0.72),
      ),
      labelLarge: _sans(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0.35,
      ),
      labelSmall: _sans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.9,
        color: scheme.onSurface.withValues(alpha: 0.62),
      ),
    );
  }

  /// Small-caps eyebrow label — section markers, table headers, overlines.
  static TextStyle eyebrow({Color? color}) {
    return _sans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.15,
      height: 1.3,
      color: color ?? WebPalette.inkSoft,
    );
  }

  static TextStyle monoData(BuildContext context, {double? fontSize}) {
    return mono(
      fontSize: fontSize ?? 13,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  /// KPI value — the serif hero number on stat tiles.
  static TextStyle metricValue(BuildContext context) {
    return serif(
      fontSize: 31,
      fontWeight: FontWeight.w600,
      height: 1.12,
      letterSpacing: -0.2,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
