import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import 'web_tokens.dart';
import 'web_typography.dart';

abstract final class WebTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BsColors.primary,
      primary: BsColors.primary,
      secondary: BsColors.accent,
      error: BsColors.danger,
      surface: BsColors.surface,
      onSurface: const Color(0xFF1D2421),
      outline: const Color(0xFF94A3B8),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF8F6F3),
      surfaceContainer: const Color(0xFFF1EFEC),
      surfaceContainerHigh: const Color(0xFFE8E6E3),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BsColors.surface,
      textTheme: WebTypography.textTheme(scheme),
      fontFamily: GoogleFonts.outfit().fontFamily,
      fontFamilyFallback: const ['Noto Sans Devanagari'],
      extensions: const [WebTokens.light],
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.2),
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BsColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.15)),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: WebTypography.textTheme(scheme).labelLarge,
        dataTextStyle: GoogleFonts.jetBrainsMono(fontSize: 13),
        headingRowColor: WidgetStateProperty.all(
          scheme.surfaceContainerLow,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BsColors.primary,
      brightness: Brightness.dark,
      secondary: BsColors.accentDark,
      error: BsColors.dangerDark,
    );

    return light().copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: WebTypography.textTheme(scheme),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
