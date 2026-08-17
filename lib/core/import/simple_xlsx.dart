import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Minimal XLSX (Office Open XML) writer/reader for string tables.
///
/// Supports a single worksheet of text/number cells — enough for product
/// import templates without pulling in the `excel` package (incompatible
/// with this project's `image` / `archive` versions).
class SimpleXlsx {
  const SimpleXlsx();

  /// Builds a single-sheet workbook from [rows] (row-major string grid).
  Uint8List encode(List<List<String>> rows, {String sheetName = 'Sheet1'}) {
    final shared = <String>[];
    final sharedIndex = <String, int>{};

    int indexOf(String value) {
      final existing = sharedIndex[value];
      if (existing != null) return existing;
      final i = shared.length;
      shared.add(value);
      sharedIndex[value] = i;
      return i;
    }

    final sheetXml = StringBuffer()
      ..write(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetData>',
      );

    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      sheetXml.write('<row r="${r + 1}">');
      for (var c = 0; c < row.length; c++) {
        final ref = '${_colLetter(c)}${r + 1}';
        final si = indexOf(row[c]);
        sheetXml.write('<c r="$ref" t="s"><v>$si</v></c>');
      }
      sheetXml.write('</row>');
    }
    sheetXml.write('</sheetData></worksheet>');

    final sharedXml = StringBuffer()
      ..write(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'count="${shared.length}" uniqueCount="${shared.length}">',
      );
    for (final s in shared) {
      sharedXml.write('<si><t>${_xmlEscape(s)}</t></si>');
    }
    sharedXml.write('</sst>');

    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypesXml))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRelsXml))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbookXml(sheetName)))
      ..addFile(
        ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRelsXml),
      )
      ..addFile(ArchiveFile.string('xl/styles.xml', _stylesXml))
      ..addFile(
        ArchiveFile.string('xl/sharedStrings.xml', sharedXml.toString()),
      )
      ..addFile(
        ArchiveFile.string('xl/worksheets/sheet1.xml', sheetXml.toString()),
      );

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Decodes the first worksheet into a row-major string grid.
  List<List<String>> decode(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final shared = _readSharedStrings(archive);
    final sheetFile = _findSheet(archive);
    if (sheetFile == null) {
      throw const FormatException('Excel file has no worksheet');
    }
    final sheetBytes = sheetFile.readBytes();
    if (sheetBytes == null) {
      throw const FormatException('Could not read worksheet');
    }
    return _parseSheet(utf8.decode(sheetBytes), shared);
  }

  List<String> _readSharedStrings(Archive archive) {
    final file = _fileNamed(archive, 'xl/sharedStrings.xml');
    if (file == null) return const [];
    final bytes = file.readBytes();
    if (bytes == null) return const [];
    final doc = XmlDocument.parse(utf8.decode(bytes));
    final out = <String>[];
    for (final si in doc.findAllElements('si')) {
      final parts = si.findAllElements('t').map((t) => t.innerText);
      out.add(parts.join());
    }
    return out;
  }

  ArchiveFile? _findSheet(Archive archive) {
    return _fileNamed(archive, 'xl/worksheets/sheet1.xml') ??
        archive.files.cast<ArchiveFile?>().firstWhere(
          (f) =>
              f != null &&
              f.isFile &&
              f.name.replaceAll('\\', '/').contains('xl/worksheets/'),
          orElse: () => null,
        );
  }

  ArchiveFile? _fileNamed(Archive archive, String path) {
    final normalized = path.replaceAll('\\', '/');
    for (final f in archive.files) {
      if (!f.isFile) continue;
      if (f.name.replaceAll('\\', '/') == normalized) return f;
    }
    return null;
  }

  List<List<String>> _parseSheet(String xml, List<String> shared) {
    final doc = XmlDocument.parse(xml);
    final rows = <int, Map<int, String>>{};
    var maxCol = 0;

    for (final rowEl in doc.findAllElements('row')) {
      final rowRef = int.tryParse(rowEl.getAttribute('r') ?? '') ?? 0;
      final rowIndex = rowRef > 0 ? rowRef - 1 : rows.length;
      final cells = rows.putIfAbsent(rowIndex, () => <int, String>{});

      for (final cell in rowEl.findElements('c')) {
        final ref = cell.getAttribute('r') ?? '';
        final col = _colIndexFromRef(ref);
        if (col < 0) continue;
        if (col > maxCol) maxCol = col;
        cells[col] = _cellValue(cell, shared);
      }
    }

    if (rows.isEmpty) return const [];

    final maxRow = rows.keys.reduce((a, b) => a > b ? a : b);
    final grid = <List<String>>[];
    for (var r = 0; r <= maxRow; r++) {
      final map = rows[r] ?? const {};
      grid.add([for (var c = 0; c <= maxCol; c++) map[c] ?? '']);
    }
    return grid;
  }

  String _cellValue(XmlElement cell, List<String> shared) {
    final type = cell.getAttribute('t');
    if (type == 'inlineStr') {
      return cell.findAllElements('t').map((t) => t.innerText).join();
    }
    final v = cell.getElement('v')?.innerText ?? '';
    if (type == 's') {
      final i = int.tryParse(v);
      if (i == null || i < 0 || i >= shared.length) return '';
      return shared[i];
    }
    return v;
  }

  static String _colLetter(int index) {
    var n = index;
    final buf = StringBuffer();
    do {
      buf.write(String.fromCharCode(65 + (n % 26)));
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return buf.toString().split('').reversed.join();
  }

  static int _colIndexFromRef(String ref) {
    final letters = StringBuffer();
    for (final code in ref.codeUnits) {
      if (code >= 65 && code <= 90) {
        letters.writeCharCode(code);
      } else {
        break;
      }
    }
    if (letters.isEmpty) return -1;
    var n = 0;
    for (final code in letters.toString().codeUnits) {
      n = n * 26 + (code - 64);
    }
    return n - 1;
  }

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static const _contentTypesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
      '</Types>';

  static const _rootRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';

  static String _workbookXml(String sheetName) =>
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets>'
      '<sheet name="${_xmlEscape(sheetName)}" sheetId="1" r:id="rId1"/>'
      '</sheets>'
      '</workbook>';

  static const _workbookRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>'
      '</Relationships>';

  static const _stylesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="1"><font><sz val="11"/><color theme="1"/><name val="Calibri"/><family val="2"/></font></fonts>'
      '<fills count="1"><fill><patternFill patternType="none"/></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>'
      '</styleSheet>';
}
