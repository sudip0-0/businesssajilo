import 'package:businesssajilo/core/utils/stock_status.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final product = const Product(
    id: '1',
    businessId: 'b',
    name: 'Test',
    stockCached: 3,
    lowStockThreshold: 5,
  );

  test('stockLevelFor detects low stock', () {
    expect(stockLevelFor(product), StockLevel.lowStock);
    expect(isLowStock(product), isTrue);
  });

  test('countLowStock counts matching products', () {
    final low = product.copyWith(stockCached: 2);
    final ok = product.copyWith(stockCached: 20);
    expect(countLowStock([product, low, ok]), 2);
  });
}
