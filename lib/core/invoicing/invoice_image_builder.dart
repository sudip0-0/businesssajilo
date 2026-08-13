import 'dart:typed_data';

import 'invoice_document.dart';
import 'invoice_paper_size.dart';
import 'invoice_pdf_builder.dart';
import 'pdf_raster_isolate.dart';

/// Renders an invoice PDF page to PNG for sharing or clipboard copy.
class InvoiceImageBuilder {
  const InvoiceImageBuilder({InvoicePdfBuilder? pdfBuilder})
    : _pdfBuilder = pdfBuilder ?? const InvoicePdfBuilder();

  final InvoicePdfBuilder _pdfBuilder;

  Future<Uint8List> buildPng(
    InvoiceDocument doc, {
    InvoicePaperSize paperSize = InvoicePaperSize.a4,
    double dpi = 180,
  }) async {
    final pdfBytes = await _pdfBuilder.build(doc, paperSize: paperSize);
    return rasterPdfFirstPageToPng(pdfBytes, dpi: dpi);
  }
}
