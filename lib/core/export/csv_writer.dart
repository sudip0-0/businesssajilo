import 'dart:convert';

/// RFC4180-style CSV with UTF-8 BOM for Excel.
class CsvWriter {
  const CsvWriter();

  String build(List<List<String>> rows) {
    final buffer = StringBuffer('\uFEFF');
    for (final row in rows) {
      buffer.writeln(row.map(_escape).join(','));
    }
    return buffer.toString();
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  List<int> encodeUtf8(String csv) => utf8.encode(csv);
}
