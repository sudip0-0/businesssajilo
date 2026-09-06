import 'dart:convert';
import 'dart:typed_data';

import 'package:businesssajilo/core/import/simple_xlsx.dart';
import 'package:businesssajilo/features/inventory/product_excel_import.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:businesssajilo/data/repositories/products_repository.dart';
import 'package:businesssajilo/data/repositories/stock_repository.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/stock_movement.dart';

void main() {
  const xlsx = SimpleXlsx();
  const importer = ProductExcelImport();

  test('round-trips sample workbook including Nepali text', () {
    final bytes = importer.buildSampleBytes();
    final grid = xlsx.decode(bytes);

    expect(grid.first, productImportHeaders);
    expect(grid[1][0], 'Cola 1L');
    expect(grid[1][1], 'कोला १ लिटर');
    expect(grid[1][4], '45');
    expect(grid[1][5], '60');
  });

  test('parses sample workbook into product rows with NPR→paisa', () {
    final bytes = importer.buildSampleBytes();
    final parsed = importer.parseBytes(
      bytes,
      filename: ProductExcelImport.sampleFileName,
    );

    expect(parsed.errors, isEmpty);
    expect(parsed.rows, hasLength(3));
    expect(parsed.rows.first.name, 'Cola 1L');
    expect(parsed.rows.first.nameNp, 'कोला १ लिटर');
    expect(parsed.rows.first.costPrice, 4500);
    expect(parsed.rows.first.referencePrice, 6000);
    expect(parsed.rows.first.lowStockThreshold, 5);
    expect(parsed.rows.first.initialQuantity, 24);
    expect(parsed.rows.first.unit, 'piece');
  });

  test('parses CSV with BOM and alternate headers', () {
    const csv =
        '\uFEFFproduct_name,cost,price,qty\n'
        'Rice 25kg,1200,1400,10\n';
    final parsed = importer.parseBytes(
      Uint8List.fromList(utf8.encode(csv)),
      filename: 'products.csv',
    );

    expect(parsed.rows, hasLength(1));
    expect(parsed.rows.single.name, 'Rice 25kg');
    expect(parsed.rows.single.costPrice, 120000);
    expect(parsed.rows.single.referencePrice, 140000);
    expect(parsed.rows.single.initialQuantity, 10);
  });

  test('collects invalid rows without aborting valid ones', () {
    final parsed = importer.parseRows([
      productImportHeaders,
      ['Good Item', '', '', 'piece', '10', '20', '1', '5'],
      ['', '', '', 'piece', '10', '20', '1', '5'],
      ['Bad Price', '', '', 'piece', 'xx', '20', '1', '5'],
    ]);

    expect(parsed.rows, hasLength(1));
    expect(parsed.rows.single.name, 'Good Item');
    expect(parsed.errors, hasLength(2));
    expect(parsed.errors[0].code, 'missing_name');
    expect(parsed.errors[1].code, 'invalid_cost');
  });

  test('rejects fractional quantities and thresholds rather than rounding', () {
    for (final value in ['1.5', '0.1', 'NaN', 'Infinity', '1e2', '1,,000']) {
      final parsed = importer.parseRows([
        productImportHeaders,
        ['Bad Qty', '', '', 'piece', '0.29', '1.01', '0', value],
        ['Bad Threshold', '', '', 'piece', '0', '0', value, '0'],
      ]);
      expect(parsed.rows, isEmpty, reason: value);
      expect(parsed.errors.map((e) => e.code), [
        'invalid_qty',
        'invalid_threshold',
      ]);
    }
  });

  test('rejects excessive price precision and preserves valid paisa', () {
    final parsed = importer.parseRows([
      productImportHeaders,
      ['Exact', '', '', 'piece', '0.29', '1.01', '1', '2'],
      ['Invalid', '', '', 'piece', '1.001', '2', '0', '0'],
    ]);
    expect(parsed.rows.single.costPrice, 29);
    expect(parsed.rows.single.referencePrice, 101);
    expect(parsed.errors.single.code, 'invalid_cost');
  });

  test(
    'stock failure identifies created product and replay never duplicates writes',
    () async {
      final products = _Products();
      final stock = _Stock();
      final runner = ProductImportRunner(
        products: products,
        stock: stock,
        memberId: 'm1',
      );
      const rows = [
        ProductImportRow(
          rowNumber: 2,
          name: 'Rice',
          sku: 'RICE',
          initialQuantity: 2,
        ),
      ];
      final first = await runner.run(rows);
      expect(first.imported, 0);
      expect(first.failed, 1);
      expect(first.errors.single.code, 'stock_unconfirmed');
      expect(first.errors.single.productId, 'p1');
      expect(first.errors.single.sku, 'RICE');
      final replay = await runner.run(rows);
      expect(replay.errors.single.code, 'stock_unconfirmed');
      expect(products.creates, 1);
      expect(stock.calls, 1);
    },
  );

  test('successful rows are not recreated when resuming a session', () async {
    final products = _Products();
    final runner = ProductImportRunner(
      products: products,
      stock: _Stock(),
      memberId: 'm1',
    );
    const row = ProductImportRow(rowNumber: 2, name: 'Rice');
    expect((await runner.run([row])).imported, 1);
    expect(
      (await runner.run([
        row,
        const ProductImportRow(rowNumber: 3, name: 'Tea'),
      ])).imported,
      2,
    );
    expect(products.creates, 2);
  });

  test(
    'confirmed opening stock is only written once on session replay',
    () async {
      final products = _Products();
      final stock = _Stock()..fail = false;
      final runner = ProductImportRunner(
        products: products,
        stock: stock,
        memberId: 'm1',
      );
      const rows = [
        ProductImportRow(rowNumber: 2, name: 'Rice', initialQuantity: 2),
      ];
      expect((await runner.run(rows)).imported, 1);
      expect((await runner.run(rows)).imported, 1);
      expect(products.creates, 1);
      expect(stock.calls, 1);
    },
  );

  test(
    'missing member does not silently omit requested opening stock',
    () async {
      final products = _Products();
      final stock = _Stock();
      final result =
          await ProductImportRunner(
            products: products,
            stock: stock,
            memberId: null,
          ).run([
            const ProductImportRow(
              rowNumber: 2,
              name: 'Rice',
              initialQuantity: 2,
            ),
          ]);
      expect(result.imported, 0);
      expect(result.errors.single.code, 'missing_member');
      expect(products.creates, 0);
      expect(stock.calls, 0);
    },
  );

  test('ambiguous product creation cannot be blindly replayed', () async {
    final products = _Products()..fail = true;
    final runner = ProductImportRunner(
      products: products,
      stock: _Stock(),
      memberId: 'm1',
    );
    const rows = [ProductImportRow(rowNumber: 2, name: 'Rice')];
    expect((await runner.run(rows)).errors.single.code, 'create_unconfirmed');
    await runner.run(rows);
    expect(products.creates, 1);
  });

  test('concurrent runs cannot send the same row twice', () async {
    final products = _Products();
    final runner = ProductImportRunner(
      products: products,
      stock: _Stock(),
      memberId: 'm1',
    );
    const rows = [ProductImportRow(rowNumber: 2, name: 'Rice')];
    final first = runner.run(rows);
    await expectLater(runner.run(rows), throwsStateError);
    expect((await first).imported, 1);
    expect(products.creates, 1);
  });

  test('rejects workbook without name header', () {
    expect(
      () => importer.parseRows([
        ['sku', 'unit'],
        ['A1', 'piece'],
      ]),
      throwsA(
        isA<ProductImportParseException>().having(
          (e) => e.message,
          'message',
          'missing_header',
        ),
      ),
    );
  });
}

class _Products implements ProductsRepository {
  int creates = 0;
  bool fail = false;

  @override
  Future<Product> create({
    required String name,
    String? nameNp,
    String? sku,
    required String unit,
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
  }) async {
    creates++;
    if (fail) throw StateError('response lost');
    return Product(id: 'p$creates', businessId: 'b1', name: name, unit: unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Stock implements StockRepository {
  int calls = 0;
  bool fail = true;

  @override
  Future<StockMovement> stockIn({
    required String productId,
    required int qty,
    required String createdByMemberId,
    String? reason,
  }) async {
    calls++;
    // Simulates a committed write whose response was lost. Retrying is unsafe.
    if (fail) throw StateError('response lost');
    return StockMovement(
      id: 's1',
      businessId: 'b1',
      productId: productId,
      type: StockMovementType.stockIn,
      qtyDelta: qty,
      createdBy: createdByMemberId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
