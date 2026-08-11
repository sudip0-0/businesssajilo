import 'dart:convert';
import 'dart:typed_data';

import 'package:businesssajilo/core/import/simple_xlsx.dart';
import 'package:businesssajilo/features/inventory/product_excel_import.dart';
import 'package:flutter_test/flutter_test.dart';

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
