import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/bs_date.dart';
import '../utils/money.dart';
import 'pdf_fonts.dart';
import 'pdf_text_table.dart';
import 'statement_document.dart';

/// Builds A4 PDF bytes for customer ledger statements. Long statements
/// paginate automatically via [pw.MultiPage].
///
/// Amounts use Nepali grouping with no currency symbol or paisa.
class StatementPdfBuilder {
  const StatementPdfBuilder();

  static const _titleSize = 20.0;
  static const _businessSize = 16.0;
  static const _bodySize = 12.0;
  static const _tableHeaderSize = 12.0;
  static const _tableCellSize = 11.0;
  static const _totalSize = 13.0;

  Future<Uint8List> build(StatementDocument doc) async {
    final theme = await PdfFonts.loadTheme();
    final pdf = pw.Document(theme: theme);

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
          style: const pw.TextStyle(
            fontSize: _titleSize,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          doc.businessDisplayName,
          style: const pw.TextStyle(
            fontSize: _businessSize,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        if (doc.business.address != null && doc.business.address!.isNotEmpty)
          pw.Text(
            doc.business.address!,
            style: const pw.TextStyle(fontSize: _bodySize),
            textAlign: pw.TextAlign.center,
          ),
        if (doc.business.phone != null && doc.business.phone!.isNotEmpty)
          pw.Text(
            doc.business.phone!,
            style: const pw.TextStyle(fontSize: _bodySize),
            textAlign: pw.TextAlign.center,
          ),
        pw.Divider(),
        pw.Text(
          '${labels.customer}: ${doc.customerLabel}',
          style: const pw.TextStyle(fontSize: _bodySize),
        ),
        pw.Text(
          '${labels.period}: $period',
          style: const pw.TextStyle(fontSize: _bodySize),
        ),
      ],
    );
  }

  pw.Widget _table(StatementDocument doc) {
    final labels = doc.labels;
    return buildPdfTextTable(
      headers: [
        labels.date,
        labels.description,
        labels.debit,
        labels.credit,
        labels.balance,
      ],
      headerStyle: const pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: _tableHeaderSize,
      ),
      cellStyle: const pw.TextStyle(fontSize: _tableCellSize),
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
        ['', labels.openingBalance, '', '', _money(doc.openingBalance)],
        ...doc.lines.map(
          (line) => [
            BsDate.both(line.date, locale: doc.locale),
            line.description,
            line.debit == 0 ? '' : _money(line.debit),
            line.credit == 0 ? '' : _money(line.credit),
            _money(line.balance),
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
          style: const pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: _totalSize,
          ),
        ),
        pw.Text(
          _money(doc.closingBalance),
          style: const pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: _totalSize,
          ),
        ),
      ],
    );
  }

  String _money(int amountPaisa) {
    return formatNpr(Paisa(amountPaisa), showSymbol: false, showPaisa: false);
  }
}
