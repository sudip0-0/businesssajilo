import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a [pw.Table] from header labels and row data.
/// Prefer this helper over the deprecated PDF table text-array APIs.
pw.Table buildPdfTextTable({
  required List<String> headers,
  required List<List<String>> data,
  pw.TextStyle? headerStyle,
  pw.TextStyle? cellStyle,
  Map<int, pw.Alignment>? cellAlignments,
  Map<int, pw.TableColumnWidth>? columnWidths,
}) {
  pw.Widget cell(
    String text, {
    required int column,
    pw.TextStyle? style,
    bool header = false,
  }) {
    final align = cellAlignments?[column] ?? pw.Alignment.centerLeft;
    return pw.Container(
      alignment: align,
      padding: pw.EdgeInsets.symmetric(vertical: header ? 4 : 3, horizontal: 2),
      child: pw.Text(text, style: style),
    );
  }

  final rows = <pw.TableRow>[
    pw.TableRow(
      repeat: true,
      children: [
        for (var i = 0; i < headers.length; i++)
          cell(headers[i], column: i, style: headerStyle, header: true),
      ],
    ),
    for (final row in data)
      pw.TableRow(
        children: [
          for (var i = 0; i < row.length; i++)
            cell(row[i], column: i, style: cellStyle),
        ],
      ),
  ];

  return pw.Table(
    columnWidths: columnWidths,
    border: const pw.TableBorder(
      horizontalInside: const pw.BorderSide(
        width: 0.4,
        color: PdfColors.grey400,
      ),
      bottom: const pw.BorderSide(width: 0.6, color: PdfColors.grey600),
      top: const pw.BorderSide(width: 0.6, color: PdfColors.grey600),
    ),
    children: rows,
  );
}
