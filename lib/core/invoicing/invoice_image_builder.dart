import 'dart:typed_data';

import 'invoice_document.dart';
import 'invoice_pdf_builder.dart';
import 'pdf_raster_isolate.dart';

/// Renders invoice PDF first page to PNG for WhatsApp sharing.
class InvoiceImageBuilder {
  const InvoiceImageBuilder({InvoicePdfBuilder? pdfBuilder})
    : _pdfBuilder = pdfBuilder ?? const InvoicePdfBuilder();

  final InvoicePdfBuilder _pdfBuilder;

  Future<Uint8List> buildPng(InvoiceDocument doc, {double dpi = 180}) async {
    final pdfBytes = await _pdfBuilder.build(doc);
    return rasterPdfFirstPageToPng(pdfBytes, dpi: dpi);
  }
}
