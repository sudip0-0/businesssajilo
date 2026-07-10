import 'package:flutter/material.dart';

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
      fontFamily: WebTypography.fontFamily,
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
        fillColor: scheme.surface,
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
        color: scheme.surface,
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
        dataTextStyle: TextStyle(
          fontFamily: WebTypography.fontFamily,
          fontSize: 13,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headingRowColor: WidgetStateProperty.all(scheme.surface),
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
        backgroundColor: scheme.surface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
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
    final border = scheme.outline.withValues(alpha: 0.35);
    final surface = scheme.surface;
    final elevated = scheme.surfaceContainerHigh;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: WebTypography.textTheme(scheme),
      fontFamily: WebTypography.fontFamily,
      fontFamilyFallback: const ['Noto Sans Devanagari'],
      extensions: [
        WebTokens.light.copyWith(
          // Keep layout metrics; colors come from ColorScheme.
        ),
      ],
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
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
          foregroundColor: scheme.primary,
          minimumSize: const Size(64, 40),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 40),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        labelStyle: WebTypography.textTheme(scheme).labelLarge,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsRadii.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsRadii.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsRadii.lg),
          side: BorderSide(color: border),
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
        dataTextStyle: TextStyle(
          fontFamily: WebTypography.fontFamily,
          fontSize: 13,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headingRowColor: WidgetStateProperty.all(elevated),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return scheme.surfaceContainerHighest;
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
          side: BorderSide(color: border),
        ),
        backgroundColor: elevated,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: elevated,
        modalBackgroundColor: elevated,
      ),
    );
  }
}
