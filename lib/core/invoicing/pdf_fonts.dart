import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Unicode-capable PDF theme (Inter + Noto Sans Devanagari fallback).
///
/// Default Helvetica cannot draw Nepali/Devanagari or many punctuation glyphs
/// (e.g. em dash, रू). Load once per document via [loadTheme].
class PdfFonts {
  PdfFonts._();

  static pw.ThemeData? _cached;

  /// Returns a cached [pw.ThemeData] with Inter base/bold and Devanagari fallback.
  static Future<pw.ThemeData> loadTheme() async {
    final cached = _cached;
    if (cached != null) return cached;

    final base = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Bold.ttf'),
    );
    final devanagari = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf'),
    );

    return _cached = pw.ThemeData.withFont(
      base: base,
      bold: bold,
      fontFallback: [devanagari],
    );
  }

  /// Clears the cached theme (for tests).
  static void clearCache() => _cached = null;
}
