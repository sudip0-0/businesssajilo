import 'package:businesssajilo/core/router/role_routes.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roleHomePath', () {
    test('maps each role to its shell route', () {
      expect(roleHomePath(Role.owner), '/owner');
      expect(roleHomePath(Role.sales), '/sales');
      expect(roleHomePath(Role.warehouse), '/warehouse');
      expect(roleHomePath(Role.customer), '/customer');
      expect(roleHomePath(null), '/login');
    });
  });

  group('pathAllowedForRole', () {
    test('allows only matching role prefix', () {
      expect(pathAllowedForRole('/owner', Role.owner), isTrue);
      expect(pathAllowedForRole('/sales/billing', Role.sales), isTrue);
      expect(pathAllowedForRole('/owner', Role.sales), isFalse);
      expect(pathAllowedForRole('/warehouse', Role.customer), isFalse);
    });
  });
}
