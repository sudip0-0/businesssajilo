import 'package:pdf/pdf.dart';

/// Paper sizes offered when printing or downloading a bill PDF.
enum InvoicePaperSize {
  a4,
  a5;

  PdfPageFormat get pageFormat => switch (this) {
    InvoicePaperSize.a4 => PdfPageFormat.a4,
    InvoicePaperSize.a5 => PdfPageFormat.a5,
  };

  /// Typography / spacing multiplier relative to A4.
  double get scale => switch (this) {
    InvoicePaperSize.a4 => 1.0,
    InvoicePaperSize.a5 => 0.88,
  };

  double get margin => switch (this) {
    InvoicePaperSize.a4 => 36,
    InvoicePaperSize.a5 => 28,
  };
}
