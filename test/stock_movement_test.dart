import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/stock_movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StockMovementType serializes stock_in for Postgres', () {
    const movement = StockMovement(
      id: 'id',
      businessId: 'biz',
      productId: 'prod',
      type: StockMovementType.stockIn,
      qtyDelta: 5,
      createdBy: 'member',
    );
    final json = movement.toJson();
    expect(json['type'], 'stock_in');
  });

  test('StockMovement deserializes stock_in from Postgres', () {
    final movement = StockMovement.fromJson({
      'id': 'id',
      'business_id': 'biz',
      'product_id': 'prod',
      'type': 'stock_in',
      'qty_delta': 5,
      'created_by': 'member',
    });
    expect(movement.type, StockMovementType.stockIn);
  });
}
