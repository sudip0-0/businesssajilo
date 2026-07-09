import 'dart:typed_data';

import 'package:printing/printing.dart';

import 'invoice_document.dart';
import 'invoice_pdf_builder.dart';

/// Renders invoice PDF first page to PNG for WhatsApp sharing.
class InvoiceImageBuilder {
  const InvoiceImageBuilder({InvoicePdfBuilder? pdfBuilder})
    : _pdfBuilder = pdfBuilder ?? const InvoicePdfBuilder();

  final InvoicePdfBuilder _pdfBuilder;

  Future<Uint8List> buildPng(InvoiceDocument doc, {double dpi = 180}) async {
    final pdfBytes = await _pdfBuilder.build(doc);
    final images = Printing.raster(pdfBytes, pages: [0], dpi: dpi);
    PdfRaster? first;
    await for (final page in images) {
      first = page;
      break;
    }
    if (first == null) {
      throw StateError('Failed to rasterize invoice PDF');
    }
    return first.toPng();
  }
}
