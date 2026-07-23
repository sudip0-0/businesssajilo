import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'invoice_document.dart';
import 'invoice_image_builder.dart';
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

  Future<Uint8List> buildPdfBytes(InvoiceDocument doc) =>
      _pdfBuilder.build(doc);

  Future<Uint8List> buildPngBytes(InvoiceDocument doc) =>
      _imageBuilder.buildPng(doc);

  Future<void> printPdf(InvoiceDocument doc) async {
    final bytes = await _pdfBuilder.build(doc);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> sharePdf(InvoiceDocument doc, {String? subject}) async {
    final bytes = await _pdfBuilder.build(doc);
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

  Future<void> downloadPdf(InvoiceDocument doc) async {
    final bytes = await _pdfBuilder.build(doc);
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_safeName(doc.documentNo)}.pdf',
      );
      return;
    }
    await sharePdf(doc);
  }

  String _safeName(String documentNo) =>
      documentNo.replaceAll(RegExp(r'[^\w\-]+'), '_');
}
