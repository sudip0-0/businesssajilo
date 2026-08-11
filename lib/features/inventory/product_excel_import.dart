import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/import/simple_xlsx.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/stock_repository.dart';
import 'product_form_screen.dart';

/// Canonical Excel / CSV column headers for product import.
const productImportHeaders = <String>[
  'name',
  'name_np',
  'sku',
  'unit',
  'cost_price',
  'reference_price',
  'low_stock_threshold',
  'initial_quantity',
];

class ProductImportRow {
  const ProductImportRow({
    required this.rowNumber,
    required this.name,
    this.nameNp,
    this.sku,
    this.unit = 'piece',
    this.costPrice = 0,
    this.referencePrice = 0,
    this.lowStockThreshold = 0,
    this.initialQuantity = 0,
  });

  /// 1-based spreadsheet row (including header offset).
  final int rowNumber;
  final String name;
  final String? nameNp;
  final String? sku;
  final String unit;
  final int costPrice;
  final int referencePrice;
  final int lowStockThreshold;
  final int initialQuantity;
}

class ProductImportParseException implements Exception {
  ProductImportParseException(this.message, {this.rowNumber});

  final String message;
  final int? rowNumber;

  @override
  String toString() => message;
}

class ProductImportRowError {
  const ProductImportRowError({
    required this.rowNumber,
    required this.code,
  });

  final int rowNumber;

  /// Machine code: missing_name | invalid_cost | invalid_price |
  /// invalid_threshold | invalid_qty | create_failed
  final String code;
}

class ProductImportParseResult {
  const ProductImportParseResult({
    required this.rows,
    required this.errors,
  });

  final List<ProductImportRow> rows;
  final List<ProductImportRowError> errors;
}

class ProductImportResult {
  const ProductImportResult({
    required this.imported,
    required this.failed,
    required this.errors,
  });

  final int imported;
  final int failed;
  final List<ProductImportRowError> errors;

  int get total => imported + failed;
}

/// Builds the sample workbook and parses uploaded Excel/CSV product files.
class ProductExcelImport {
  const ProductExcelImport({SimpleXlsx? xlsx})
    : _xlsx = xlsx ?? const SimpleXlsx();

  final SimpleXlsx _xlsx;

  static const sampleFileName = 'businesssajilo_product_import_sample.xlsx';

  Uint8List buildSampleBytes() {
    return _xlsx.encode([
      productImportHeaders,
      [
        'Cola 1L',
        'कोला १ लिटर',
        '',
        'piece',
        '45',
        '60',
        '5',
        '24',
      ],
      [
        'Mineral Water',
        'मिनरल वाटर',
        '',
        'piece',
        '15',
        '25',
        '10',
        '48',
      ],
      [
        'Juice Pack',
        'जुस प्याक',
        '',
        'piece',
        '35',
        '50',
        '5',
        '12',
      ],
    ], sheetName: 'Products');
  }

  ProductImportParseResult parseBytes(Uint8List bytes, {String? filename}) {
    final name = (filename ?? '').toLowerCase();
    try {
      final rows = name.endsWith('.csv')
          ? _parseCsv(utf8.decode(bytes, allowMalformed: true))
          : _xlsx.decode(bytes);
      return parseRows(rows);
    } on FormatException {
      throw ProductImportParseException('invalid_file');
    } catch (e) {
      if (e is ProductImportParseException) rethrow;
      throw ProductImportParseException('invalid_file');
    }
  }

  ProductImportParseResult parseRows(List<List<String>> rows) {
    if (rows.isEmpty) {
      throw ProductImportParseException('empty');
    }

    final headerIndex = _findHeaderRow(rows);
    if (headerIndex < 0) {
      throw ProductImportParseException('missing_header');
    }

    final headerMap = _mapHeaders(rows[headerIndex]);
    if (!headerMap.containsKey('name')) {
      throw ProductImportParseException('missing_name_column');
    }

    final out = <ProductImportRow>[];
    final errors = <ProductImportRowError>[];

    for (var i = headerIndex + 1; i < rows.length; i++) {
      final raw = rows[i];
      if (_isBlankRow(raw)) continue;

      String cell(String key) {
        final col = headerMap[key];
        if (col == null || col >= raw.length) return '';
        return raw[col].trim();
      }

      final rowNumber = i + 1;
      final name = cell('name');
      if (name.isEmpty) {
        errors.add(
          ProductImportRowError(rowNumber: rowNumber, code: 'missing_name'),
        );
        continue;
      }

      final unitRaw = cell('unit');
      final cost = _tryParseMoneyPaisa(cell('cost_price'));
      if (cost == null) {
        errors.add(
          ProductImportRowError(rowNumber: rowNumber, code: 'invalid_cost'),
        );
        continue;
      }
      final ref = _tryParseMoneyPaisa(cell('reference_price'));
      if (ref == null) {
        errors.add(
          ProductImportRowError(rowNumber: rowNumber, code: 'invalid_price'),
        );
        continue;
      }
      final threshold = _tryParseNonNegInt(cell('low_stock_threshold'));
      if (threshold == null) {
        errors.add(
          ProductImportRowError(
            rowNumber: rowNumber,
            code: 'invalid_threshold',
          ),
        );
        continue;
      }
      final qty = _tryParseNonNegInt(cell('initial_quantity'));
      if (qty == null) {
        errors.add(
          ProductImportRowError(rowNumber: rowNumber, code: 'invalid_qty'),
        );
        continue;
      }

      final nameNp = cell('name_np');
      final sku = cell('sku');

      out.add(
        ProductImportRow(
          rowNumber: rowNumber,
          name: name,
          nameNp: nameNp.isEmpty ? null : nameNp,
          sku: sku.isEmpty ? null : sku,
          unit: unitRaw.isEmpty ? 'piece' : unitRaw,
          costPrice: cost,
          referencePrice: ref,
          lowStockThreshold: threshold,
          initialQuantity: qty,
        ),
      );
    }

    if (out.isEmpty && errors.isEmpty) {
      throw ProductImportParseException('no_rows');
    }
    return ProductImportParseResult(rows: out, errors: errors);
  }

  int _findHeaderRow(List<List<String>> rows) {
    final limit = rows.length < 5 ? rows.length : 5;
    for (var i = 0; i < limit; i++) {
      final map = _mapHeaders(rows[i]);
      if (map.containsKey('name')) return i;
    }
    return -1;
  }

  Map<String, int> _mapHeaders(List<String> header) {
    final map = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final key = _normalizeHeader(header[i]);
      if (key == null) continue;
      map.putIfAbsent(key, () => i);
    }
    return map;
  }

  String? _normalizeHeader(String raw) {
    final h = raw
        .trim()
        .toLowerCase()
        .replaceAll('\uFEFF', '')
        .replaceAll(RegExp(r'[\s\-]+'), '_');
    return switch (h) {
      'name' || 'product_name' || 'product' => 'name',
      'name_np' || 'name_nepali' || 'product_name_np' => 'name_np',
      'sku' || 'code' || 'product_sku' => 'sku',
      'unit' || 'uom' => 'unit',
      'cost_price' || 'cost' || 'cost_npr' => 'cost_price',
      'reference_price' ||
      'price' ||
      'selling_price' ||
      'ref_price' ||
      'reference' => 'reference_price',
      'low_stock_threshold' ||
      'low_stock' ||
      'threshold' ||
      'reorder_level' => 'low_stock_threshold',
      'initial_quantity' ||
      'initial_qty' ||
      'quantity' ||
      'qty' ||
      'stock' => 'initial_quantity',
      _ => null,
    };
  }

  bool _isBlankRow(List<String> row) =>
      row.every((c) => c.trim().isEmpty);

  /// Empty → 0. Invalid → null.
  int? _tryParseMoneyPaisa(String raw) {
    if (raw.trim().isEmpty) return 0;
    final parsed = parseNpr(raw);
    if (parsed == null || parsed.value < 0) return null;
    return parsed.value;
  }

  /// Empty → 0. Invalid → null.
  int? _tryParseNonNegInt(String raw) {
    if (raw.trim().isEmpty) return 0;
    final cleaned = raw.replaceAll(',', '').trim();
    final value = int.tryParse(cleaned) ?? double.tryParse(cleaned)?.round();
    if (value == null || value < 0) return null;
    return value;
  }

  List<List<String>> _parseCsv(String text) {
    final normalized = text.replaceFirst('\uFEFF', '').replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final rows = <List<String>>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      rows.add(_parseCsvLine(line));
    }
    return rows;
  }

  List<String> _parseCsvLine(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buf.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    out.add(buf.toString());
    return out;
  }
}

/// Creates products (and optional opening stock) from parsed Excel rows.
class ProductImportRunner {
  ProductImportRunner({
    required ProductsRepository products,
    required StockRepository stock,
    required String? memberId,
  }) : _products = products,
       _stock = stock,
       _memberId = memberId;

  final ProductsRepository _products;
  final StockRepository _stock;
  final String? _memberId;

  Future<ProductImportResult> run(
    List<ProductImportRow> rows, {
    List<ProductImportRowError> priorErrors = const [],
    void Function(int current, int total)? onProgress,
  }) async {
    var imported = 0;
    var failed = priorErrors.length;
    final errors = List<ProductImportRowError>.from(priorErrors);

    for (var i = 0; i < rows.length; i++) {
      onProgress?.call(i + 1, rows.length);
      final row = rows[i];
      try {
        final created = await _products.create(
          name: row.name,
          nameNp: row.nameNp,
          sku: row.sku ?? generateProductSku(),
          unit: row.unit,
          costPrice: row.costPrice,
          referencePrice: row.referencePrice,
          lowStockThreshold: row.lowStockThreshold,
        );
        if (row.initialQuantity > 0 && _memberId != null) {
          await _stock.stockIn(
            productId: created.id,
            qty: row.initialQuantity,
            createdByMemberId: _memberId,
          );
        }
        imported++;
      } catch (_) {
        failed++;
        errors.add(
          ProductImportRowError(
            rowNumber: row.rowNumber,
            code: 'create_failed',
          ),
        );
      }
    }

    return ProductImportResult(
      imported: imported,
      failed: failed,
      errors: errors,
    );
  }
}

final productExcelImportProvider = Provider<ProductExcelImport>(
  (ref) => const ProductExcelImport(),
);
