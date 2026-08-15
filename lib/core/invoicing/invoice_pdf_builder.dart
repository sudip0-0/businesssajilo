import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/bs_date.dart';
import '../utils/money.dart';
import '../utils/rupees_in_words.dart';
import 'invoice_document.dart';
import 'invoice_paper_size.dart';
import 'pdf_fonts.dart';

/// Builds Nepal-style bill / credit-note PDFs (A4 or A5).
///
/// Amounts are whole rupees with grouping and no currency symbol or paisa
/// column — matching a typical shop invoice without VAT.
class InvoicePdfBuilder {
  const InvoicePdfBuilder();

  static const _flexes = [7, 36, 9, 12, 14];

  static const _alignments = <pw.Alignment>[
    pw.Alignment.center,
    pw.Alignment.centerLeft,
    pw.Alignment.center,
    pw.Alignment.center,
    pw.Alignment.centerRight,
  ];

  Future<Uint8List> build(
    InvoiceDocument doc, {
    InvoicePaperSize paperSize = InvoicePaperSize.a4,
  }) async {
    final theme = await PdfFonts.loadTheme();
    final pdf = pw.Document(theme: theme);
    final scale = paperSize.scale;
    final margin = paperSize.margin;
    final pageTheme = pw.PageTheme(
      pageFormat: paperSize.pageFormat,
      margin: pw.EdgeInsets.all(margin),
      theme: theme,
      buildBackground: (context) => _pageFrame(margin),
    );

    if (_fitsOnePage(doc, paperSize)) {
      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => _buildSinglePage(doc, scale),
        ),
      );
    } else {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pageTheme,
          build: (context) => _buildOverflowBody(doc, scale),
          footer: (context) => _pageFooter(doc, context, scale),
        ),
      );
    }

    return pdf.save();
  }

  bool _fitsOnePage(InvoiceDocument doc, InvoicePaperSize paperSize) {
    final maxLines = paperSize == InvoicePaperSize.a5 ? 12 : 20;
    return doc.lines.length <= maxLines;
  }

  pw.Widget _pageFrame(double margin) {
    final inset = margin * 0.4;
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Padding(
        padding: pw.EdgeInsets.all(inset),
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.8, color: PdfColors.black),
          ),
        ),
      ),
    );
  }

  pw.Widget _buildSinglePage(InvoiceDocument doc, double scale) {
    final dateStr = BsDate.bothWithTime(doc.createdAt, locale: doc.locale);
    final fs = _Sizes(scale);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        ..._topMatter(doc, dateStr, fs),
        pw.Expanded(child: _itemArea(doc, fs, pinTotalToBottom: true)),
        ..._closing(doc, fs),
        _pageFooter(doc, null, scale),
      ],
    );
  }

  List<pw.Widget> _buildOverflowBody(InvoiceDocument doc, double scale) {
    final dateStr = BsDate.bothWithTime(doc.createdAt, locale: doc.locale);
    final fs = _Sizes(scale);

    return [
      ..._topMatter(doc, dateStr, fs),
      _itemArea(doc, fs, pinTotalToBottom: false),
      ..._closing(doc, fs),
    ];
  }

  List<pw.Widget> _topMatter(InvoiceDocument doc, String dateStr, _Sizes fs) {
    return [
      _header(doc, fs),
      pw.SizedBox(height: fs.gap * 1.1),
      _invoiceMeta(doc, dateStr, fs),
      pw.SizedBox(height: fs.gap * 0.7),
      _underlinedField(doc.labels.name, doc.customerLabel, fs),
      _underlinedField(doc.labels.address, doc.customerAddress ?? '', fs),
      if (doc.provisionalNotice != null) ...[
        pw.SizedBox(height: fs.gap * 0.4),
        pw.Text(
          doc.provisionalNotice!,
          style: pw.TextStyle(fontSize: fs.small, color: PdfColors.grey700),
        ),
      ],
      pw.SizedBox(height: fs.gap * 0.5),
    ];
  }

  List<pw.Widget> _closing(InvoiceDocument doc, _Sizes fs) {
    return [
      pw.SizedBox(height: fs.gap * 0.55),
      pw.Text(
        '${doc.labels.inWords}: ${rupeesInWords(doc.grandTotal)}',
        style: pw.TextStyle(fontSize: fs.body),
      ),
      _authorized(doc, fs),
    ];
  }

  pw.Widget _header(InvoiceDocument doc, _Sizes fs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _titleAndStatus(doc, fs),
        pw.SizedBox(height: fs.gap * 0.7),
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
            padding: pw.EdgeInsets.only(top: fs.gap * 0.2),
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
      ],
    );
  }

  pw.Widget _titleAndStatus(InvoiceDocument doc, _Sizes fs) {
    final titleBox = pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: fs.gap * 1.4,
        vertical: fs.gap * 0.35,
      ),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.7)),
      child: pw.Text(
        doc.titleLabel,
        style: pw.TextStyle(
          fontSize: fs.heading,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );

    final showStatus = doc.kind == InvoiceDocumentKind.bill;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(child: pw.SizedBox()),
        titleBox,
        pw.Expanded(
          child: showStatus
              ? pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    padding: pw.EdgeInsets.symmetric(
                      horizontal: fs.gap * 1.1,
                      vertical: fs.gap * 0.35,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.7),
                    ),
                    child: pw.Text(
                      doc.statusLabel,
                      style: pw.TextStyle(
                        fontSize: fs.heading,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : pw.SizedBox(),
        ),
      ],
    );
  }

  pw.Widget _invoiceMeta(InvoiceDocument doc, String dateStr, _Sizes fs) {
    final labels = doc.labels;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            '${labels.billNo}  ${doc.documentNo}',
            style: pw.TextStyle(fontSize: fs.body),
          ),
        ),
        pw.Text(
          '${labels.date}: $dateStr',
          style: pw.TextStyle(fontSize: fs.body),
        ),
      ],
    );
  }

  pw.Widget _underlinedField(String label, String value, _Sizes fs) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: fs.gap * 0.45),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: fs.body,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 8 * fs.scale),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.6)),
              ),
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(value, style: pw.TextStyle(fontSize: fs.body)),
            ),
          ),
        ],
      ),
    );
  }

  /// Item list with no inner grid. On a single page the total sits at the
  /// bottom of this area; leftover space between items and total stays blank.
  pw.Widget _itemArea(
    InvoiceDocument doc,
    _Sizes fs, {
    required bool pinTotalToBottom,
  }) {
    final labels = doc.labels;
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: fs.tableHeader,
    );
    final cellStyle = pw.TextStyle(fontSize: fs.tableCell);
    final boldCell = pw.TextStyle(
      fontSize: fs.tableCell,
      fontWeight: pw.FontWeight.bold,
    );

    final itemRows = [
      for (var i = 0; i < doc.lines.length; i++)
        _dataRow(
          [
            '${i + 1}',
            _lineLabel(doc.lines[i], labels.discount),
            '${doc.lines[i].qty}',
            _money(doc.lines[i].rate),
            _money(doc.lines[i].lineTotal),
          ],
          fs,
          style: cellStyle,
        ),
    ];

    final totals = <pw.Widget>[
      if (doc.discount > 0)
        _dataRow(
          ['', '', '', labels.subtotal, _money(doc.itemsTotal)],
          fs,
          style: boldCell,
        ),
      if (doc.discount > 0)
        _dataRow(
          ['', '', '', labels.discount, _money(-doc.discount)],
          fs,
          style: boldCell,
        ),
      pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(width: 0.7)),
        ),
        child: _dataRow(
          ['', '', '', labels.total, _money(doc.grandTotal)],
          fs,
          style: boldCell,
        ),
      ),
      if (doc.showPartialReceived) ...[
        _dataRow(
          ['', '', '', labels.amountPaid, _money(doc.amountReceived!)],
          fs,
          style: boldCell,
        ),
        _dataRow(
          ['', '', '', labels.remainingDue, _money(doc.remainingDue)],
          fs,
          style: boldCell,
        ),
      ],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.7)),
          ),
          child: _dataRow(
            [labels.sn, labels.item, labels.qty, labels.rate, labels.amount],
            fs,
            style: headerStyle,
          ),
        ),
        ...itemRows,
        if (pinTotalToBottom) pw.Expanded(child: pw.SizedBox()),
        ...totals,
      ],
    );
  }

  pw.Widget _dataRow(List<String> values, _Sizes fs, {pw.TextStyle? style}) {
    return pw.Row(
      children: [
        for (var i = 0; i < values.length; i++)
          pw.Expanded(
            flex: _flexes[i],
            child: pw.Container(
              alignment: _alignments[i],
              padding: pw.EdgeInsets.symmetric(
                vertical: 5 * fs.scale,
                horizontal: 4 * fs.scale,
              ),
              child: pw.Text(values[i], style: style),
            ),
          ),
      ],
    );
  }

  pw.Widget _authorized(InvoiceDocument doc, _Sizes fs) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: fs.gap * 2.4),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.SizedBox(
          width: 130 * fs.scale,
          child: pw.Column(
            children: [
              pw.Container(
                width: double.infinity,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(width: 0.7)),
                ),
                padding: pw.EdgeInsets.only(top: fs.gap * 0.35),
                child: pw.Text(
                  doc.labels.authorized,
                  style: pw.TextStyle(fontSize: fs.small),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  pw.Widget _pageFooter(
    InvoiceDocument doc,
    pw.Context? context,
    double scale,
  ) {
    final fs = _Sizes(scale);
    final pageLabel = context == null
        ? '1 / 1'
        : '${context.pageNumber} / ${context.pagesCount}';
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: fs.gap * 0.4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            doc.businessDisplayName,
            style: pw.TextStyle(fontSize: fs.small, color: PdfColors.grey600),
          ),
          pw.Text(
            pageLabel,
            style: pw.TextStyle(fontSize: fs.small, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  String _lineLabel(InvoiceLine line, String discountLabel) {
    if (line.discount <= 0) return line.name;
    return '${line.name}  ($discountLabel ${_money(-line.discount)})';
  }

  /// Bill print amounts: Nepali grouping, no currency symbol, no paisa.
  String _money(int amountPaisa) {
    return formatNpr(Paisa(amountPaisa), showSymbol: false, showPaisa: false);
  }
}

class _Sizes {
  const _Sizes(this.scale);

  final double scale;

  double get title => 16 * scale;
  double get heading => 11 * scale;
  double get body => 10 * scale;
  double get tableHeader => 9 * scale;
  double get tableCell => 9 * scale;
  double get small => 8 * scale;
  double get gap => 8 * scale;
}
