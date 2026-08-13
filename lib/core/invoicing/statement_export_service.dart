import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../export/clipboard_image.dart';
import 'pdf_raster_isolate.dart';
import 'statement_document.dart';
import 'statement_pdf_builder.dart';

/// Share customer ledger statements as PDF, or copy the first page as PNG.
class StatementExportService {
  const StatementExportService({StatementPdfBuilder? pdfBuilder})
    : _pdfBuilder = pdfBuilder ?? const StatementPdfBuilder();

  final StatementPdfBuilder _pdfBuilder;

  Future<Uint8List> buildPdfBytes(StatementDocument doc) =>
      _pdfBuilder.build(doc);

  /// Renders the first page as PNG (long statements should use PDF).
  Future<Uint8List> buildPngBytes(StatementDocument doc) async {
    final pdfBytes = await _pdfBuilder.build(doc);
    return rasterPdfFirstPageToPng(pdfBytes);
  }

  /// Rasterizes the statement PDF and copies the PNG.
  ///
  /// [loadDocument] may be async; on web the clipboard write starts
  /// immediately so it still counts as a user gesture.
  Future<void> copyPng(Future<StatementDocument> Function() loadDocument) {
    return copyPngToClipboard(
      Future(() async {
        final doc = await loadDocument();
        return buildPngBytes(doc);
      }),
    );
  }

  Future<void> sharePdf(StatementDocument doc, {String? subject}) async {
    final bytes = await _pdfBuilder.build(doc);
    final name = _fileName(doc);
    if (kIsWeb) {
      // Browser download; share sheets are not available on web.
      await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
      return;
    }
    await Share.shareXFiles([
      XFile.fromData(bytes, name: '$name.pdf', mimeType: 'application/pdf'),
    ], subject: subject ?? name);
  }

  String _fileName(StatementDocument doc) {
    final customer = doc.customerLabel.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final date = doc.toDate.toIso8601String().split('T').first;
    return 'statement_${customer}_$date';
  }
}

final statementExportServiceProvider = Provider((ref) {
  return const StatementExportService();
});
