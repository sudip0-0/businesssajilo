import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'web_palette.dart';
import 'web_tokens.dart';
import 'web_typography.dart';

abstract final class WebTheme {
  /// "Digital Ledger" light theme — warm paper, ink navy, brass accents.
  static ThemeData light() {
    final scheme = AppTheme.lightScheme.copyWith(
      primary: WebPalette.navy,
      onPrimary: Colors.white,
      surface: WebPalette.card,
      onSurface: WebPalette.ink,
      onSurfaceVariant: WebPalette.inkSoft,
      outline: WebPalette.inkSoft,
      outlineVariant: WebPalette.hairline,
      surfaceContainerLowest: WebPalette.cardBright,
      surfaceContainerLow: const Color(0xFFF4F0E6),
      surfaceContainer: WebPalette.paperDeep,
      surfaceContainerHigh: const Color(0xFFE8E2D3),
      surfaceContainerHighest: const Color(0xFFE0D9C7),
    );
    final textTheme = WebTypography.textTheme(scheme);
    const buttonRadius = BorderRadius.all(Radius.circular(6));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: WebPalette.paper,
      textTheme: textTheme,
      fontFamily: WebTypography.fontFamily,
      fontFamilyFallback: const ['Noto Sans Devanagari'],
      extensions: const [WebTokens.light],
      splashColor: WebPalette.navy.withValues(alpha: 0.07),
      hoverColor: WebPalette.navy.withValues(alpha: 0.04),
      highlightColor: WebPalette.navy.withValues(alpha: 0.04),
      focusColor: WebPalette.navy.withValues(alpha: 0.08),
      dividerTheme: const DividerThemeData(
        color: WebPalette.hairline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return WebPalette.inkFaint.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.pressed)) {
              return WebPalette.navyPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return WebPalette.navyHover;
            }
            return WebPalette.navy;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.08),
          ),
          minimumSize: WidgetStateProperty.all(const Size(64, 40)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: buttonRadius),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 1;
            return 0;
          }),
          textStyle: WidgetStateProperty.all(
            textTheme.labelLarge?.copyWith(
              fontSize: 13.5,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return WebPalette.inkFaint;
            }
            return WebPalette.ink;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return WebPalette.paperDeep.withValues(alpha: 0.55);
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStateProperty.all(
            WebPalette.navy.withValues(alpha: 0.05),
          ),
          minimumSize: WidgetStateProperty.all(const Size(64, 40)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return const BorderSide(color: WebPalette.hairlineStrong);
            }
            return const BorderSide(color: WebPalette.hairline);
          }),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: buttonRadius),
          ),
          textStyle: WidgetStateProperty.all(
            textTheme.labelLarge?.copyWith(fontSize: 13.5, letterSpacing: 0.3),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(WebPalette.navy),
          overlayColor: WidgetStateProperty.all(
            WebPalette.navy.withValues(alpha: 0.06),
          ),
          minimumSize: WidgetStateProperty.all(const Size(48, 36)),
          textStyle: WidgetStateProperty.all(
            textTheme.labelLarge?.copyWith(fontSize: 13.5, letterSpacing: 0.3),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(WebPalette.inkSoft),
          overlayColor: WidgetStateProperty.all(
            WebPalette.navy.withValues(alpha: 0.06),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WebPalette.cardBright,
        labelStyle: textTheme.labelLarge?.copyWith(color: WebPalette.inkSoft),
        hintStyle: textTheme.bodyMedium?.copyWith(color: WebPalette.inkFaint),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTokens.light.inputRadius),
          borderSide: const BorderSide(color: WebPalette.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTokens.light.inputRadius),
          borderSide: const BorderSide(color: WebPalette.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTokens.light.inputRadius),
          borderSide: const BorderSide(color: WebPalette.navy, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTokens.light.inputRadius),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: WebPalette.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WebTokens.light.cardRadius),
          side: const BorderSide(color: WebPalette.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: WebPalette.paperDeep,
        selectedColor: WebPalette.navyWash,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsRadii.full),
        ),
        side: const BorderSide(color: WebPalette.hairline),
        labelStyle: textTheme.labelLarge,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return WebPalette.navy;
            }
            return WebPalette.inkSoft;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return WebPalette.navy.withValues(alpha: 0.09);
            }
            if (states.contains(WidgetState.hovered)) {
              return WebPalette.paperDeep.withValues(alpha: 0.5);
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: WebPalette.hairline),
          ),
          minimumSize: WidgetStateProperty.all(const Size(72, 34)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14),
          ),
          textStyle: WidgetStateProperty.all(
            textTheme.labelLarge?.copyWith(fontSize: 12.5),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: buttonRadius),
          ),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: WebTypography.eyebrow(),
        dataTextStyle: TextStyle(
          fontFamily: WebTypography.fontFamily,
          fontFamilyFallback: const ['Noto Sans Devanagari'],
          fontSize: 13,
          height: 1.4,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headingRowColor: WidgetStateProperty.all(WebPalette.cardBright),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return WebPalette.paperDeep.withValues(alpha: 0.55);
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
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: WebPalette.hairline),
        ),
        backgroundColor: WebPalette.card,
        titleTextStyle: textTheme.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: WebPalette.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: WebPalette.cardBright,
        ),
        actionTextColor: WebPalette.brassBright,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: WebPalette.ink,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: WebPalette.cardBright),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: WebPalette.navy,
        linearTrackColor: WebPalette.hairline,
        circularTrackColor: WebPalette.hairline,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: WebPalette.card,
        indicatorColor: WebPalette.navyWash,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelSmall ?? const TextStyle();
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: WebPalette.navy, letterSpacing: 0.4);
          }
          return base.copyWith(color: WebPalette.inkSoft);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: WebPalette.navy, size: 21);
          }
          return const IconThemeData(color: WebPalette.inkSoft, size: 21);
        }),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: WebPalette.card,
        foregroundColor: WebPalette.ink,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: WebPalette.card,
        modalBackgroundColor: WebPalette.card,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: WebPalette.cardBright,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: WebPalette.hairline),
        ),
        labelTextStyle: WidgetStateProperty.all(textTheme.bodyMedium),
      ),
    );
  }
}
