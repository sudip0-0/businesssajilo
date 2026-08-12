import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/bs_date.dart';
import '../utils/money.dart';
import 'invoice_document.dart';
import 'invoice_paper_size.dart';
import 'pdf_fonts.dart';
import 'pdf_text_table.dart';

/// Builds simple, readable bill / credit-note PDFs (A4 or A5).
class InvoicePdfBuilder {
  const InvoicePdfBuilder();

  Future<Uint8List> build(
    InvoiceDocument doc, {
    InvoicePaperSize paperSize = InvoicePaperSize.a4,
  }) async {
    final theme = await PdfFonts.loadTheme();
    final pdf = pw.Document(theme: theme);
    final scale = paperSize.scale;
    final margin = paperSize.margin;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: paperSize.pageFormat,
        margin: pw.EdgeInsets.all(margin),
        build: (context) => _buildBody(doc, scale),
        footer: (context) => _pageFooter(doc, context, scale),
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildBody(InvoiceDocument doc, double scale) {
    final labels = doc.labels;
    final dateStr = BsDate.both(doc.createdAt, locale: doc.locale);
    final fs = _Sizes(scale);

    return [
      _header(doc, fs),
      pw.SizedBox(height: fs.gap * 1.2),
      _metaBlock(doc, dateStr, fs),
      if (doc.provisionalNotice != null) ...[
        pw.SizedBox(height: fs.gap * 0.6),
        pw.Text(
          doc.provisionalNotice!,
          style: pw.TextStyle(fontSize: fs.small, color: PdfColors.grey700),
        ),
      ],
      pw.SizedBox(height: fs.gap),
      buildPdfTextTable(
        headers: [
          labels.sn,
          labels.item,
          labels.qty,
          labels.rate,
          labels.amount,
        ],
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: fs.tableHeader,
        ),
        cellStyle: pw.TextStyle(fontSize: fs.tableCell),
        cellAlignments: {
          0: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
        },
        columnWidths: {
          0: const pw.FlexColumnWidth(0.7),
          1: const pw.FlexColumnWidth(3.4),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1.4),
          4: const pw.FlexColumnWidth(1.5),
        },
        data: [
          for (var i = 0; i < doc.lines.length; i++)
            [
              '${i + 1}',
              doc.lines[i].name,
              '${doc.lines[i].qty}',
              _money(doc.lines[i].rate),
              _money(doc.lines[i].lineTotal),
            ],
        ],
      ),
      pw.SizedBox(height: fs.gap),
      _totals(doc, fs),
      if (doc.footerNote != null) ...[
        pw.SizedBox(height: fs.gap * 1.5),
        pw.Center(
          child: pw.Text(
            doc.footerNote!,
            style: pw.TextStyle(
              fontSize: fs.body,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    ];
  }

  pw.Widget _header(InvoiceDocument doc, _Sizes fs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          doc.businessDisplayName,
          style: pw.TextStyle(
            fontSize: fs.title,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        if (doc.business.address != null &&
            doc.business.address!.trim().isNotEmpty)
          pw.Padding(
            padding: pw.EdgeInsets.only(top: fs.gap * 0.25),
            child: pw.Text(
              doc.business.address!,
              style: pw.TextStyle(fontSize: fs.body),
              textAlign: pw.TextAlign.center,
            ),
          ),
        if (doc.business.phone != null && doc.business.phone!.trim().isNotEmpty)
          pw.Text(
            doc.business.phone!,
            style: pw.TextStyle(fontSize: fs.body),
            textAlign: pw.TextAlign.center,
          ),
        pw.SizedBox(height: fs.gap * 0.8),
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: fs.gap * 0.45),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 1),
              bottom: pw.BorderSide(width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                doc.titleLabel,
                style: pw.TextStyle(
                  fontSize: fs.heading,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                doc.statusLabel,
                style: pw.TextStyle(
                  fontSize: fs.body,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _metaBlock(InvoiceDocument doc, String dateStr, _Sizes fs) {
    final labels = doc.labels;
    return pw.Column(
      children: [
        _metaRow(labels.billNo, doc.documentNo, fs),
        _metaRow(labels.date, dateStr, fs),
        _metaRow(labels.customer, doc.customerLabel, fs),
      ],
    );
  }

  pw.Widget _metaRow(String label, String value, _Sizes fs) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: fs.gap * 0.2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110 * fs.scale,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: fs.body,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: fs.body,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _totals(InvoiceDocument doc, _Sizes fs) {
    final labels = doc.labels;
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220 * fs.scale,
        child: pw.Column(
          children: [
            _totalRow(labels.subtotal, doc.itemsTotal, fs),
            if (doc.discount > 0)
              _totalRow(labels.discount, -doc.discount, fs),
            pw.SizedBox(height: fs.gap * 0.35),
            pw.Container(
              padding: pw.EdgeInsets.symmetric(
                vertical: fs.gap * 0.45,
                horizontal: fs.gap * 0.5,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    labels.grandTotal,
                    style: pw.TextStyle(
                      fontSize: fs.heading,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _money(doc.grandTotal),
                    style: pw.TextStyle(
                      fontSize: fs.heading,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, int amountPaisa, _Sizes fs) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: fs.gap * 0.15),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fs.body)),
          pw.Text(
            _money(amountPaisa),
            style: pw.TextStyle(fontSize: fs.body),
          ),
        ],
      ),
    );
  }

  pw.Widget _pageFooter(
    InvoiceDocument doc,
    pw.Context context,
    double scale,
  ) {
    final fs = _Sizes(scale);
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: fs.gap * 0.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            doc.businessDisplayName,
            style: pw.TextStyle(fontSize: fs.small, color: PdfColors.grey600),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: fs.small, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Bill print amounts: Nepali grouping, no currency symbol.
  String _money(int amountPaisa) {
    return formatNpr(Paisa(amountPaisa), showSymbol: false, showPaisa: false);
  }
}

class _Sizes {
  const _Sizes(this.scale);

  final double scale;

  double get title => 18 * scale;
  double get heading => 12 * scale;
  double get body => 10 * scale;
  double get tableHeader => 9 * scale;
  double get tableCell => 9 * scale;
  double get small => 8 * scale;
  double get gap => 8 * scale;
}
