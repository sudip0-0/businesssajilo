import 'package:pdf/pdf.dart';

/// Paper sizes offered when printing or downloading a bill PDF.
enum InvoicePaperSize {
  a4,
  a2;

  /// ISO A2 is not built into [PdfPageFormat]; define it explicitly.
  PdfPageFormat get pageFormat => switch (this) {
    InvoicePaperSize.a4 => PdfPageFormat.a4,
    InvoicePaperSize.a2 => const PdfPageFormat(
      420 * PdfPageFormat.mm,
      594 * PdfPageFormat.mm,
    ),
  };

  /// Typography / spacing multiplier relative to A4.
  double get scale => switch (this) {
    InvoicePaperSize.a4 => 1.0,
    InvoicePaperSize.a2 => 1.55,
  };

  double get margin => switch (this) {
    InvoicePaperSize.a4 => 36,
    InvoicePaperSize.a2 => 56,
  };
}
