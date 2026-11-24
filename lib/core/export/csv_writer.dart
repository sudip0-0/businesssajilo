import 'dart:convert';

/// RFC4180-style CSV with UTF-8 BOM for Excel and formula-injection defense.
class CsvWriter {
  const CsvWriter();

  static final _safeSignedNumeric = RegExp(r'^-(?:रू\s*)?[0-9०-९][0-9०-९,.]*$');

  String build(List<List<String>> rows) {
    final buffer = StringBuffer('\uFEFF');
    for (final row in rows) {
      buffer.writeln(row.map(_escape).join(','));
    }
    return buffer.toString();
  }

  String _escape(String value) {
    final safe = _neutralizeFormula(value);
    if (safe.contains(',') ||
        safe.contains('"') ||
        safe.contains('\n') ||
        safe.contains('\r')) {
      return '"${safe.replaceAll('"', '""')}"';
    }
    return safe;
  }

  /// Prefixes potentially executable spreadsheet formulas (`=`, `+`, `@`, tab,
  /// CR, or non-numeric `-...`) with a leading single quote so Excel / Sheets
  /// treats them as literal text while leaving signed numeric/NPR cells intact.
  String _neutralizeFormula(String value) {
    if (value.isEmpty) return value;
    final first = value.codeUnitAt(0);
    if (first == 0x3D /* = */ ||
        first == 0x2B /* + */ ||
        first == 0x40 /* @ */ ||
        first == 0x09 /* \t */ ||
        first == 0x0D /* \r */ ) {
      return "'$value";
    }
    if (first == 0x2D /* - */ && !_safeSignedNumeric.hasMatch(value)) {
      return "'$value";
    }
    return value;
  }

  List<int> encodeUtf8(String csv) => utf8.encode(csv);
}
