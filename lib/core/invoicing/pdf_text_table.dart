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
  final headerCells = headers
      .map(
        (h) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: pw.Text(h, style: headerStyle),
        ),
      )
      .toList();

  final rows = <pw.TableRow>[
    pw.TableRow(children: headerCells),
    for (final row in data)
      pw.TableRow(
        children: [
          for (var i = 0; i < row.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
              child: pw.Align(
                alignment: cellAlignments?[i] ?? pw.Alignment.centerLeft,
                child: pw.Text(row[i], style: cellStyle),
              ),
            ),
        ],
      ),
  ];

  return pw.Table(
    columnWidths: columnWidths,
    border: pw.TableBorder.all(width: 0.3),
    children: rows,
  );
}
