import 'package:businesssajilo/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orderTransitions allows placed to received and billed', () {
    expect(
      orderTransitions[OrderStatus.placed],
      equals({OrderStatus.received, OrderStatus.billed}),
    );
  });

  test('orderTransitions allows received to billed only', () {
    expect(
      orderTransitions[OrderStatus.received],
      equals({OrderStatus.billed}),
    );
  });

  test('billed is terminal', () {
    expect(orderTransitions[OrderStatus.billed], isEmpty);
  });

  test('warehouse cannot bill per RolePermissions', () {
    expect(Role.warehouse.canBill, isFalse);
    expect(Role.sales.canQuote, isTrue);
    expect(Role.customer.canQuote, isFalse);
  });
}
