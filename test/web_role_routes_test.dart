import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/web/router/web_role_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('webBillingPathAllowed', () {
    test('owner, sales and customer may reach billing routes', () {
      expect(webBillingPathAllowed(Role.owner), isTrue);
      expect(webBillingPathAllowed(Role.sales), isTrue);
      expect(webBillingPathAllowed(Role.customer), isTrue);
    });

    test('warehouse is blocked from billing routes', () {
      expect(webBillingPathAllowed(Role.warehouse), isFalse);
    });
  });
}
