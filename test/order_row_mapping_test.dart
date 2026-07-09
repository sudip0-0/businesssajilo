import 'package:businesssajilo/data/repositories/orders_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapOrderRow maps light list select with order_items(id)', () {
    final order = mapOrderRow({
      'id': 'ord-1',
      'business_id': 'biz',
      'customer_id': 'cust-1',
      'status': 'placed',
      'created_at': '2026-07-01T00:00:00Z',
      'customers': {'shop_name': 'Kirana'},
      'order_items': [
        {'id': 'item-1'},
        {'id': 'item-2'},
      ],
    });

    expect(order.id, 'ord-1');
    expect(order.customerShopName, 'Kirana');
    expect(order.status, OrderStatus.placed);
    expect(order.items, hasLength(2));
    expect(order.items.map((i) => i.id).toList(), ['item-1', 'item-2']);
    expect(order.items.every((i) => i.orderId == 'ord-1'), isTrue);
  });

  test('mapOrderRow maps full nested product payload', () {
    final order = mapOrderRow({
      'id': 'ord-2',
      'business_id': 'biz',
      'customer_id': 'cust-1',
      'status': 'confirmed',
      'created_at': '2026-07-01T00:00:00Z',
      'customers': {'shop_name': 'Mart'},
      'order_items': [
        {
          'id': 'item-9',
          'order_id': 'ord-2',
          'product_id': 'prod-1',
          'qty': 3,
          'products': {
            'name': 'Rice',
            'name_np': 'चामल',
            'unit': 'kg',
            'image_url': null,
          },
        },
      ],
    });

    expect(order.items, hasLength(1));
    expect(order.items.single.productName, 'Rice');
    expect(order.items.single.qty, 3);
    expect(order.items.single.unit, 'kg');
  });
}
