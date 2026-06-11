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
}

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BsColors.primary,
      primary: BsColors.primary,
      secondary: BsColors.accent,
      error: BsColors.danger,
      surface: BsColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BsColors.surface,
      fontFamilyFallback: const ['Noto Sans Devanagari'],
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
