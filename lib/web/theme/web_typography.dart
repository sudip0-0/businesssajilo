import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium web typography: Outfit (Geist-like) + JetBrains Mono for data.
abstract final class WebTypography {
  static TextTheme textTheme(ColorScheme scheme) {
    final outfit = GoogleFonts.outfitTextTheme();
    return outfit.copyWith(
      headlineLarge: outfit.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
        color: scheme.onSurface,
      ),
      headlineMedium: outfit.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.15,
        color: scheme.onSurface,
      ),
      headlineSmall: outfit.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.2,
        color: scheme.onSurface,
      ),
      titleLarge: outfit.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleMedium: outfit.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: outfit.bodyLarge?.copyWith(
        height: 1.55,
        color: scheme.onSurface.withValues(alpha: 0.85),
      ),
      bodyMedium: outfit.bodyMedium?.copyWith(
        height: 1.5,
        color: scheme.onSurface.withValues(alpha: 0.8),
      ),
      labelLarge: outfit.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  static TextStyle monoData(BuildContext context, {double? fontSize}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
