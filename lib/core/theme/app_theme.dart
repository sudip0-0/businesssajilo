import 'package:flutter/material.dart';

/// Brand palette per Design.md.
abstract final class BsColors {
  static const primary = Color(0xFF0F6E5F); // deep teal
  static const accent = Color(0xFFF2A33C); // marigold
  static const success = Color(0xFF2E7D32);
  static const danger = Color(0xFFC62828);
  static const info = Color(0xFF1565C0);
  static const surface = Color(0xFFFAF8F5);
  static const text = Color(0xFF1D2421);

  // Status colors adjusted for dark surfaces (higher luminance for contrast).
  static const successDark = Color(0xFF81C784);
  static const dangerDark = Color(0xFFEF9A9A);
  static const infoDark = Color(0xFF90CAF9);
  static const accentDark = Color(0xFFFFC069);

  /// Amber text dark enough for >= 4.5:1 contrast on the light tinted chip
  /// background (color-blind safe alongside the leading icon).
  static const amberTextOnTint = Color(0xFF8A5A00);
}

abstract final class AppTheme {
  static const _textTheme = TextTheme(
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45),
    bodySmall: TextStyle(fontSize: 12, height: 1.4),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 11, height: 1.3),
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BsColors.primary,
      primary: BsColors.primary,
      secondary: BsColors.accent,
      error: BsColors.danger,
      surface: BsColors.surface,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: BsColors.surface,
      cardTheme: _cardTheme(Colors.white),
      inputDecorationTheme: _inputTheme(Colors.white),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BsColors.primary,
      brightness: Brightness.dark,
      secondary: BsColors.accentDark,
      error: BsColors.dangerDark,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: _cardTheme(scheme.surfaceContainer),
      inputDecorationTheme: _inputTheme(scheme.surfaceContainerHigh),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme,
      fontFamilyFallback: const ['Noto Sans Devanagari'],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static CardThemeData _cardTheme(Color color) => CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      );

  static InputDecorationTheme _inputTheme(Color fill) => InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );
}

/// Status color helpers that adapt to the active brightness.
extension BsStatusColors on ColorScheme {
  Color get successColor =>
      brightness == Brightness.dark ? BsColors.successDark : BsColors.success;
  Color get dangerColor =>
      brightness == Brightness.dark ? BsColors.dangerDark : BsColors.danger;
  Color get infoColor =>
      brightness == Brightness.dark ? BsColors.infoDark : BsColors.info;
  Color get accentColor =>
      brightness == Brightness.dark ? BsColors.accentDark : BsColors.accent;
}
