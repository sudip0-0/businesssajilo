import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/bs_date.dart';
import '../utils/money.dart';
import 'statement_document.dart';

/// Builds A4 PDF bytes for customer ledger statements. Long statements
/// paginate automatically via [pw.MultiPage].
class StatementPdfBuilder {
  const StatementPdfBuilder();

  Future<Uint8List> build(StatementDocument doc) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(doc),
          pw.SizedBox(height: 12),
          _table(doc),
          pw.SizedBox(height: 12),
          _totals(doc),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _header(StatementDocument doc) {
    final labels = doc.labels;
    final period = [
      if (doc.fromDate != null) BsDate.both(doc.fromDate!, locale: doc.locale),
      BsDate.both(doc.toDate, locale: doc.locale),
    ].join(' — ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          labels.title.toUpperCase(),
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          doc.businessDisplayName,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        if (doc.business.address != null && doc.business.address!.isNotEmpty)
          pw.Text(doc.business.address!, textAlign: pw.TextAlign.center),
        if (doc.business.phone != null && doc.business.phone!.isNotEmpty)
          pw.Text(doc.business.phone!, textAlign: pw.TextAlign.center),
        pw.Divider(),
        pw.Text('${labels.customer}: ${doc.customerLabel}'),
        pw.Text('${labels.period}: $period'),
      ],
    );
  }

  pw.Widget _table(StatementDocument doc) {
    final labels = doc.labels;
    return pw.Table.fromTextArray(
      headers: [
        labels.date,
        labels.description,
        labels.debit,
        labels.credit,
        labels.balance,
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(3.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.8),
      },
      data: [
        [
          '',
          labels.openingBalance,
          '',
          '',
          formatNpr(Paisa(doc.openingBalance), showPaisa: false),
        ],
        ...doc.lines.map(
          (line) => [
            BsDate.both(line.date, locale: doc.locale),
            line.description,
            line.debit == 0
                ? ''
                : formatNpr(Paisa(line.debit), showPaisa: false),
            line.credit == 0
                ? ''
                : formatNpr(Paisa(line.credit), showPaisa: false),
            formatNpr(Paisa(line.balance), showPaisa: false),
          ],
        ),
      ],
    );
  }

  pw.Widget _totals(StatementDocument doc) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          doc.labels.closingBalance,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          formatNpr(Paisa(doc.closingBalance), showPaisa: false),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}
