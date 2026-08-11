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

  test('warehouse can create bills but not view balances or full bill ops', () {
    expect(Role.warehouse.canBill, isFalse);
    expect(Role.warehouse.canCreateBills, isTrue);
    expect(Role.warehouse.canViewCustomerBalance, isFalse);
    expect(Role.warehouse.canRecordPayments, isFalse);
    expect(Role.sales.canCreateBills, isTrue);
    expect(Role.sales.canViewCustomerBalance, isTrue);
    expect(Role.sales.canQuote, isTrue);
    expect(Role.customer.canQuote, isFalse);
  });

  test('owner and sales can manage products; warehouse cannot', () {
    expect(Role.owner.canManageProducts, isTrue);
    expect(Role.sales.canManageProducts, isTrue);
    expect(Role.warehouse.canManageProducts, isFalse);
    expect(Role.customer.canManageProducts, isFalse);
  });
}
