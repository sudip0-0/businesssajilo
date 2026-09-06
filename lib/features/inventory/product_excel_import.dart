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
    this.productId,
    this.productName,
    this.sku,
  });

  final int rowNumber;

  /// Machine code: missing_name | invalid_cost | invalid_price |
  /// invalid_threshold | invalid_qty | create_failed
  /// | create_unconfirmed | stock_unconfirmed | missing_member
  final String code;

  /// Present when creation was acknowledged but opening stock was not.
  final String? productId;
  final String? productName;
  final String? sku;
}

class ProductImportParseResult {
  const ProductImportParseResult({required this.rows, required this.errors});

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
      ['Cola 1L', 'कोला १ लिटर', '', 'piece', '45', '60', '5', '24'],
      ['Mineral Water', 'मिनरल वाटर', '', 'piece', '15', '25', '10', '48'],
      ['Juice Pack', 'जुस प्याक', '', 'piece', '35', '50', '5', '12'],
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

  bool _isBlankRow(List<String> row) => row.every((c) => c.trim().isEmpty);

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
    // Reuse exact decimal/group validation, allowing only whole quantities.
    final parsed = parseNpr(raw);
    if (parsed == null || parsed.value < 0 || parsed.value % 100 != 0) {
      return null;
    }
    return parsed.value ~/ 100;
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

  // One runner is one import session. Row numbers identify rows in that file.
  // Keep acknowledged and ambiguous writes so a resumed run only attempts rows
  // that have not been sent. These repositories allocate IDs internally, so a
  // lost response cannot safely be retried (especially append-only stock).
  final _completed = <int>{};
  final _unconfirmed = <int, ProductImportRowError>{};
  bool _running = false;

  Future<ProductImportResult> run(
    List<ProductImportRow> rows, {
    List<ProductImportRowError> priorErrors = const [],
    void Function(int current, int total)? onProgress,
  }) async {
    if (_running) throw StateError('Import session already running');
    _running = true;
    try {
      var imported = 0;
      final errors = List<ProductImportRowError>.from(priorErrors);

      // Chunked processing: each chunk runs its rows through create+stockIn
      // sequentially (per-row error isolation requires one row at a time), but
      // progress is emitted per chunk boundary so the UI updates less often on
      // large sheets.
      const chunkSize = 25;
      for (var i = 0; i < rows.length; i++) {
        if (i % chunkSize == 0) {
          await Future<void>.delayed(Duration.zero); // yield between chunks
        }
        onProgress?.call(i + 1, rows.length);
        final row = rows[i];
        if (_completed.contains(row.rowNumber)) {
          imported++;
          continue;
        }
        final previous = _unconfirmed[row.rowNumber];
        if (previous != null) {
          errors.add(previous);
          continue;
        }
        if (row.initialQuantity > 0 &&
            (_memberId == null || _memberId.isEmpty)) {
          errors.add(
            ProductImportRowError(
              rowNumber: row.rowNumber,
              code: 'missing_member',
            ),
          );
          continue;
        }
        final sku = row.sku ?? generateProductSku();
        String? productId;
        try {
          final created = await _products.create(
            name: row.name,
            nameNp: row.nameNp,
            sku: sku,
            unit: row.unit,
            costPrice: row.costPrice,
            referencePrice: row.referencePrice,
            lowStockThreshold: row.lowStockThreshold,
          );
          productId = created.id;
          if (row.initialQuantity > 0) {
            await _stock.stockIn(
              productId: productId,
              qty: row.initialQuantity,
              createdByMemberId: _memberId!,
            );
          }
          _completed.add(row.rowNumber);
          imported++;
        } catch (_) {
          final error = ProductImportRowError(
            rowNumber: row.rowNumber,
            code: productId == null
                ? 'create_unconfirmed'
                : 'stock_unconfirmed',
            productId: productId,
            productName: row.name,
            sku: sku,
          );
          _unconfirmed[row.rowNumber] = error;
          errors.add(error);
        }
      }

      return ProductImportResult(
        imported: imported,
        failed: errors.length,
        errors: errors,
      );
    } finally {
      _running = false;
    }
  }
}

final productExcelImportProvider = Provider<ProductExcelImport>(
  (ref) => const ProductExcelImport(),
);
