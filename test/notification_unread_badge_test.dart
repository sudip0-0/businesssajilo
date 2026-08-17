import 'package:businesssajilo/core/utils/app_prefs.dart';
import 'package:businesssajilo/domain/models/notification_item.dart';
import 'package:businesssajilo/features/notifications/providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('excludeMutedNotifications', () {
    const dues = NotificationItem(
      id: 'n1',
      businessId: 'b1',
      recipientMemberId: 'm1',
      type: 'dues_reminder',
    );
    const chat = NotificationItem(
      id: 'n2',
      businessId: 'b1',
      recipientMemberId: 'm1',
      type: 'chat_message',
    );

    test('drops dues reminders when mute is on', () {
      const muted = NotificationMutePrefs(dues: true);
      expect(excludeMutedNotifications([dues, chat], muted).map((n) => n.id), [
        'n2',
      ]);
    });

    test('keeps dues reminders when mute is off', () {
      const unmuted = NotificationMutePrefs(dues: false);
      expect(
        excludeMutedNotifications([dues, chat], unmuted).map((n) => n.id),
        ['n1', 'n2'],
      );
    });
  });

  group('formatUnreadBadge', () {
    test('returns empty for zero', () {
      expect(formatUnreadBadge(0), '');
    });

    test('returns count up to 99', () {
      expect(formatUnreadBadge(1), '1');
      expect(formatUnreadBadge(99), '99');
    });

    test('caps at 99+', () {
      expect(formatUnreadBadge(100), '99+');
      expect(formatUnreadBadge(500), '99+');
    });
  });
}
