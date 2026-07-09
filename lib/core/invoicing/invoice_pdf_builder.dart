import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/bs_date.dart';
import '../utils/money.dart';
import 'invoice_document.dart';

/// Builds PDF bytes for bills and credit notes.
class InvoicePdfBuilder {
  const InvoicePdfBuilder();

  Future<Uint8List> build(InvoiceDocument doc) async {
    final pdf = pw.Document();
    final pageFormat = doc.kind == InvoiceDocumentKind.bill
        ? PdfPageFormat.roll80
        : PdfPageFormat.roll80;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(12),
        build: (context) => _buildContent(doc),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildContent(InvoiceDocument doc) {
    final dateStr = BsDate.both(doc.createdAt, locale: doc.locale);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          doc.titleLabel,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          doc.businessDisplayName,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        if (doc.business.address != null && doc.business.address!.isNotEmpty)
          pw.Text(doc.business.address!, textAlign: pw.TextAlign.center),
        if (doc.business.phone != null && doc.business.phone!.isNotEmpty)
          pw.Text(doc.business.phone!, textAlign: pw.TextAlign.center),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('No: ${doc.documentNo}'),
            pw.Text(doc.statusLabel),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text('Date: $dateStr'),
        pw.Text('Customer: ${doc.customerLabel}'),
        if (doc.provisionalNotice != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            doc.provisionalNotice!,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['Item', 'Qty', 'Rate', 'Amt'],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          data: doc.lines
              .map(
                (line) => [
                  line.name,
                  '${line.qty}',
                  formatNpr(Paisa(line.rate), showPaisa: false),
                  formatNpr(Paisa(line.lineTotal), showPaisa: false),
                ],
              )
              .toList(),
        ),
        pw.Divider(),
        _totalRow('Subtotal', doc.itemsTotal),
        if (doc.discount > 0) _totalRow('Discount', -doc.discount),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Grand Total',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              formatNpr(Paisa(doc.grandTotal), showPaisa: false),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        if (doc.footerNote != null) ...[
          pw.SizedBox(height: 12),
          pw.Text(doc.footerNote!, textAlign: pw.TextAlign.center),
        ],
      ],
    );
  }

  pw.Widget _totalRow(String label, int amountPaisa) {
    final prefix = amountPaisa < 0 ? '-' : '';
    final value = amountPaisa.abs();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text('$prefix${formatNpr(Paisa(value), showPaisa: false)}'),
        ],
      ),
    );
  }
}
