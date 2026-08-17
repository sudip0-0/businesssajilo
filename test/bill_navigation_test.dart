import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/features/billing/bill_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('billDetailPath', () {
    test('mobile uses the flat deep link', () {
      expect(billDetailPath(Role.owner, 'b1'), '/bill/b1');
      expect(billDetailPath(Role.sales, 'b1'), '/bill/b1');
      expect(billDetailPath(null, 'b1'), '/bill/b1');
    });

    test('web uses the role-prefixed billing route', () {
      expect(
        billDetailPath(Role.owner, 'b1', forceWeb: true),
        '/owner/billing/b1',
      );
      expect(
        billDetailPath(Role.sales, 'b1', forceWeb: true),
        '/sales/billing/b1',
      );
      expect(
        billDetailPath(Role.customer, 'b1', forceWeb: true),
        '/customer/billing/b1',
      );
      expect(
        billDetailPath(Role.warehouse, 'b1', forceWeb: true),
        '/warehouse/billing/b1',
      );
      expect(billDetailPath(null, 'b1', forceWeb: true), '/owner/billing/b1');
    });
  });
}
