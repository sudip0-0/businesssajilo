import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/web/router/web_role_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('webRoleRootRedirect', () {
    test('maps bare role roots to home dashboards', () {
      expect(webRoleRootRedirect('/owner'), '/owner/dashboard');
      expect(webRoleRootRedirect('/owner/'), '/owner/dashboard');
      expect(webRoleRootRedirect('/sales'), '/sales/dashboard');
      expect(webRoleRootRedirect('/warehouse'), '/warehouse/stock');
      expect(webRoleRootRedirect('/customer'), '/customer/dashboard');
    });

    test('ignores nested role paths', () {
      expect(webRoleRootRedirect('/owner/dashboard'), isNull);
      expect(webRoleRootRedirect('/customer/orders'), isNull);
      expect(webRoleRootRedirect('/login'), isNull);
    });
  });

  group('webBillingPathAllowed', () {
    test('owner, sales and customer may reach billing routes', () {
      expect(webBillingPathAllowed(Role.owner), isTrue);
      expect(webBillingPathAllowed(Role.sales), isTrue);
      expect(webBillingPathAllowed(Role.customer), isTrue);
    });

    test('warehouse may access billing routes', () {
      expect(webBillingPathAllowed(Role.warehouse), isTrue);
    });
  });
}
