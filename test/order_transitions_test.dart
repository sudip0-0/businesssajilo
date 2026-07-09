import 'package:businesssajilo/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orderTransitions allows placed to quoted', () {
    expect(orderTransitions[OrderStatus.placed], contains(OrderStatus.quoted));
  });

  test('orderTransitions allows dispatched to billed only', () {
    expect(
      orderTransitions[OrderStatus.dispatched],
      equals({OrderStatus.billed}),
    );
  });

  test('warehouse cannot bill per RolePermissions', () {
    expect(Role.warehouse.canBill, isFalse);
    expect(Role.sales.canQuote, isTrue);
    expect(Role.customer.canQuote, isFalse);
  });
}
