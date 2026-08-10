import 'package:businesssajilo/core/notifications/notification_target.dart';
import 'package:businesssajilo/core/router/role_routes.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/auth_user.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/notification_item.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationItem _item(String type, Map<String, dynamic> payload) {
  return NotificationItem(
    id: 'n1',
    businessId: 'b1',
    recipientMemberId: 'm1',
    type: type,
    payload: payload,
    createdAt: DateTime.utc(2024, 1, 1),
  );
}

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

    test('deep links respect role families', () {
      expect(pathAllowedForRole('/notifications', Role.owner), isTrue);
      expect(pathAllowedForRole('/bill/x', Role.customer), isTrue);
      expect(pathAllowedForRole('/bill/x', Role.warehouse), isFalse);
      expect(pathAllowedForRole('/product/x', Role.warehouse), isTrue);
      expect(pathAllowedForRole('/product/x', Role.customer), isFalse);
      expect(pathAllowedForRole('/order/x', Role.sales), isTrue);
      expect(pathAllowedForRole('/order/x', Role.customer), isTrue);
    });
  });

  group('forced password change routing', () {
    test('mustChangePassword session blocks normal home paths', () {
      const session = SessionState(
        user: AuthUser(id: 'u1', email: 'staff@test.com'),
        member: Member(
          id: 'm1',
          businessId: 'b1',
          authUserId: 'u1',
          role: Role.sales,
          displayName: 'Staff',
          mustChangePassword: true,
        ),
      );
      expect(session.mustChangePassword, isTrue);
      expect(session.isAuthenticated, isTrue);
      expect(roleHomePath(Role.sales), '/sales');
      expect(pathAllowedForRole('/change-password', Role.sales), isFalse);
    });
  });

  group('resolveNotificationTarget', () {
    test('routes each emitted type to a registered path', () {
      final cases = <(String, Map<String, dynamic>, String?)>[
        ('chat_message', {'order_id': 'o1'}, '/order/o1'),
        ('quote_received', {'order_id': 'o1'}, '/order/o1'),
        ('quote_accepted', {'order_id': 'o1'}, '/order/o1'),
        ('payment_recorded', {'bill_id': 'b1'}, '/bill/b1'),
        ('low_stock', {'product_id': 'p1'}, '/product/p1'),
        ('negative_stock', {'product_id': 'p1'}, '/product/p1'),
        ('order_placed', {'order_id': 'o1'}, '/order/o1'),
        ('order_received', {'order_id': 'o1'}, '/order/o1'),
        ('order_status', {'order_id': 'o1'}, '/order/o1'),
        ('unknown_type', {}, null),
      ];

      for (final (type, payload, path) in cases) {
        final target = resolveNotificationTarget(_item(type, payload));
        if (path == null) {
          expect(target, isA<NotificationNonNavigable>(), reason: type);
        } else {
          expect(target, isA<NotificationNavigate>(), reason: type);
          expect((target as NotificationNavigate).path, path, reason: type);
        }
      }
    });

    test('customer can open payment bills; warehouse cannot', () {
      final item = _item('payment_recorded', {'bill_id': 'b1'});
      final customer = resolveNotificationTarget(item, role: Role.customer);
      expect(customer, isA<NotificationNavigate>());
      expect(
        (customer as NotificationNavigate).path,
        '/bill/b1',
      );

      final warehouse = resolveNotificationTarget(item, role: Role.warehouse);
      expect(warehouse, isA<NotificationNonNavigable>());
    });

    test('web path mapping preserves order and customer bills', () {
      expect(
        webPathForNotificationTarget(
          role: Role.owner,
          mobilePath: '/order/o1',
        ),
        '/owner/orders/o1',
      );
      expect(
        webPathForNotificationTarget(
          role: Role.customer,
          mobilePath: '/bill/b1',
        ),
        '/customer/billing/b1',
      );
    });
  });
}
