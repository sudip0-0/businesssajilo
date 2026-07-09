import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import 'web_tokens.dart';
import 'web_typography.dart';

abstract final class WebTheme {
  static ThemeData light() {
    final scheme = AppTheme.lightScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BsColors.background,
      textTheme: WebTypography.textTheme(scheme),
      fontFamily: GoogleFonts.inter().fontFamily,
      fontFamilyFallback: const ['Noto Sans Devanagari'],
      extensions: const [WebTokens.light],
      dividerTheme: const DividerThemeData(
        color: BsColors.border,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BsColors.primary,
          foregroundColor: BsColors.onPrimary,
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsRadii.md),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BsColors.primary,
          minimumSize: const Size(64, 40),
          side: const BorderSide(color: BsColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BsColors.primary,
          minimumSize: const Size(48, 40),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: WebTypography.textTheme(scheme).labelLarge,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsRadii.md),
          borderSide: const BorderSide(color: BsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsRadii.md),
          borderSide: const BorderSide(color: BsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsRadii.md),
          borderSide: const BorderSide(color: BsColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsRadii.lg),
          side: const BorderSide(color: BsColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsRadii.full),
        ),
        side: BorderSide.none,
        labelStyle: WebTypography.textTheme(scheme).labelLarge,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(88, 36)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BsRadii.md),
            ),
          ),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: WebTypography.textTheme(scheme).labelLarge?.copyWith(
          letterSpacing: 0.8,
          color: scheme.onSurface.withValues(alpha: 0.7),
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headingRowColor: WidgetStateProperty.all(Colors.white),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return BsColors.rowHover;
          }
          return null;
        }),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 24,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsRadii.lg),
          side: const BorderSide(color: BsColors.border),
        ),
        backgroundColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: BsColors.text,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BsColors.primary,
      brightness: Brightness.dark,
      secondary: BsColors.successDark,
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
          borderRadius: BorderRadius.circular(BsRadii.lg),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsRadii.md),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
