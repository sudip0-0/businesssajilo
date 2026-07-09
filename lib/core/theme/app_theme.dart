import 'package:flutter/material.dart';

/// Brand palette per Design.md — corporate navy, success green, warning amber.
abstract final class BsColors {
  static const primary = Color(0xFF00236F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF1E3A8A);
  static const onPrimaryContainer = Color(0xFF90A8FF);

  static const secondary = Color(0xFF006C49);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const onSecondaryContainer = Color(0xFF00714D);

  /// Amber accent for warnings, pending, and partial payment states.
  static const accent = Color(0xFFF39461);
  static const accentContainer = Color(0xFF6E2C00);
  static const amberTextOnTint = Color(0xFF773205);

  static const success = Color(0xFF006C49);
  static const danger = Color(0xFFBA1A1A);
  static const info = Color(0xFF264191);

  static const surface = Color(0xFFFAF8FF);
  static const background = Color(0xFFF9FAFB);
  static const text = Color(0xFF1A1B21);
  static const textCharcoal = Color(0xFF111827);

  static const outline = Color(0xFF757682);
  static const outlineVariant = Color(0xFFC5C5D3);
  static const border = Color(0xFFE5E7EB);
  static const rowHover = Color(0xFFF3F4F6);

  static const successDark = Color(0xFF6CF8BB);
  static const dangerDark = Color(0xFFFF8A80);
  static const infoDark = Color(0xFF90A8FF);
  static const accentDark = Color(0xFFF39461);
}

abstract final class BsRadii {
  static const sm = 2.0;
  static const md = 4.0;
  static const lg = 8.0;
  static const xl = 12.0;
  static const full = 9999.0;
}

abstract final class BsElevation {
  static const level2 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -1,
    ),
  ];

  static const level3 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
  ];
}

abstract final class AppTheme {
  static const _textTheme = TextTheme(
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.43),
    bodySmall: TextStyle(fontSize: 12, height: 1.33),
    labelLarge: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.27,
    ),
  );

  static ColorScheme get lightScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: BsColors.primary,
    onPrimary: BsColors.onPrimary,
    primaryContainer: BsColors.primaryContainer,
    onPrimaryContainer: BsColors.onPrimaryContainer,
    secondary: BsColors.secondary,
    onSecondary: BsColors.onSecondary,
    secondaryContainer: BsColors.secondaryContainer,
    onSecondaryContainer: BsColors.onSecondaryContainer,
    tertiary: BsColors.accentContainer,
    onTertiary: BsColors.onPrimary,
    error: BsColors.danger,
    onError: BsColors.onPrimary,
    surface: BsColors.surface,
    onSurface: BsColors.text,
    outline: BsColors.outline,
    outlineVariant: BsColors.outlineVariant,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF4F3FA),
    surfaceContainer: Color(0xFFEEEDF4),
    surfaceContainerHigh: Color(0xFFE9E7EF),
  );

  static ThemeData light() {
    final scheme = lightScheme;

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: BsColors.background,
      cardTheme: _cardTheme(Colors.white),
      inputDecorationTheme: _inputTheme(Colors.white, scheme),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BsColors.primary,
      brightness: Brightness.dark,
      secondary: BsColors.successDark,
      error: BsColors.dangerDark,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: _cardTheme(scheme.surfaceContainer),
      inputDecorationTheme: _inputTheme(scheme.surfaceContainerHigh, scheme),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme,
      fontFamilyFallback: const ['Noto Sans Devanagari'],
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: BsColors.secondary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _textTheme.labelLarge?.copyWith(color: BsColors.secondary);
          }
          return _textTheme.labelLarge;
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: BsColors.secondary);
          }
          return IconThemeData(color: scheme.onSurface);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: BsColors.secondary.withValues(alpha: 0.12),
        selectedIconTheme: const IconThemeData(color: BsColors.secondary),
        selectedLabelTextStyle: _textTheme.labelLarge?.copyWith(
          color: BsColors.secondary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsRadii.md),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsRadii.full),
        ),
      ),
    );
  }

  static CardThemeData _cardTheme(Color color) => CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BsRadii.lg),
      side: const BorderSide(color: BsColors.border),
    ),
    color: color,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  );

  static InputDecorationTheme _inputTheme(Color fill, ColorScheme scheme) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        labelStyle: _textTheme.labelLarge,
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
  Color get warningColor => brightness == Brightness.dark
      ? BsColors.accentDark
      : BsColors.amberTextOnTint;
}
