import 'package:businesssajilo/core/l10n/app_localizations_en.dart';
import 'package:businesssajilo/domain/models/notification_item.dart';
import 'package:businesssajilo/features/notifications/notification_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notificationTitle maps known types', () {
    final l10n = AppLocalizationsEn();
    final item = const NotificationItem(
      id: '1',
      businessId: 'b',
      recipientMemberId: 'm',
      type: 'order_placed',
    );
    expect(notificationTitle(l10n, item), 'New order placed');
  });

  test('dues reminder title includes the customer shop name', () {
    final l10n = AppLocalizationsEn();
    final named = NotificationItem(
      id: '1',
      businessId: 'b',
      recipientMemberId: 'm',
      type: 'dues_reminder',
      payload: const {'shop_name': 'Ram Store'},
    );
    expect(notificationTitle(l10n, named), 'Customer Ram Store dues reminder');

    final unnamed = const NotificationItem(
      id: '2',
      businessId: 'b',
      recipientMemberId: 'm',
      type: 'dues_reminder',
    );
    expect(notificationTitle(l10n, unnamed), 'Outstanding dues reminder');
  });

  test('notificationIcon returns icon per type', () {
    expect(notificationIcon('chat_message').codePoint, isNotNull);
    expect(notificationIcon('unknown').codePoint, isNotNull);
  });
}
