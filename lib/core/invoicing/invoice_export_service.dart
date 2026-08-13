import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../export/clipboard_image.dart';
import 'invoice_document.dart';
import 'invoice_image_builder.dart';
import 'invoice_paper_size.dart';
import 'invoice_pdf_builder.dart';

/// Print, download, and share invoices as PDF or PNG.
class InvoiceExportService {
  const InvoiceExportService({
    InvoicePdfBuilder? pdfBuilder,
    InvoiceImageBuilder? imageBuilder,
  }) : _pdfBuilder = pdfBuilder ?? const InvoicePdfBuilder(),
       _imageBuilder = imageBuilder ?? const InvoiceImageBuilder();

  final InvoicePdfBuilder _pdfBuilder;
  final InvoiceImageBuilder _imageBuilder;

  Future<Uint8List> buildPdfBytes(
    InvoiceDocument doc, {
    InvoicePaperSize paperSize = InvoicePaperSize.a4,
  }) => _pdfBuilder.build(doc, paperSize: paperSize);

  Future<Uint8List> buildPngBytes(
    InvoiceDocument doc, {
    InvoicePaperSize paperSize = InvoicePaperSize.a4,
  }) => _imageBuilder.buildPng(doc, paperSize: paperSize);

  /// Rasterizes the invoice PDF at [paperSize] and copies the PNG.
  ///
  /// [loadDocument] may be async; on web the clipboard write starts
  /// immediately so it still counts as a user gesture.
  Future<void> copyPng(
    Future<InvoiceDocument> Function() loadDocument, {
    required InvoicePaperSize paperSize,
  }) {
    return copyPngToClipboard(
      Future(() async {
        final doc = await loadDocument();
        return _imageBuilder.buildPng(doc, paperSize: paperSize);
      }),
    );
  }

  Future<void> printPdf(
    InvoiceDocument doc, {
    InvoicePaperSize paperSize = InvoicePaperSize.a4,
  }) async {
    final bytes = await _pdfBuilder.build(doc, paperSize: paperSize);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      format: paperSize.pageFormat,
    );
  }

  Future<void> sharePdf(
    InvoiceDocument doc, {
    InvoicePaperSize paperSize = InvoicePaperSize.a4,
    String? subject,
  }) async {
    final bytes = await _pdfBuilder.build(doc, paperSize: paperSize);
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: '${_safeName(doc.documentNo)}.pdf',
        mimeType: 'application/pdf',
      ),
    ], subject: subject ?? doc.documentNo);
  }

  Future<void> sharePng(
    InvoiceDocument doc, {
    String? subject,
    String? text,
  }) async {
    final bytes = await _imageBuilder.buildPng(doc);
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: '${_safeName(doc.documentNo)}.png',
          mimeType: 'image/png',
        ),
      ],
      subject: subject ?? doc.documentNo,
      text: text,
    );
  }

  Future<void> downloadPdf(
    InvoiceDocument doc, {
    InvoicePaperSize paperSize = InvoicePaperSize.a4,
  }) async {
    final bytes = await _pdfBuilder.build(doc, paperSize: paperSize);
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_safeName(doc.documentNo)}.pdf',
      );
      return;
    }
    await sharePdf(doc, paperSize: paperSize);
  }

  String _safeName(String documentNo) =>
      documentNo.replaceAll(RegExp(r'[^\w\-]+'), '_');
}
