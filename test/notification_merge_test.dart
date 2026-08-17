import 'package:businesssajilo/domain/models/notification_item.dart';
import 'package:businesssajilo/features/notifications/providers.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationItem _item(String id, {bool unread = true, DateTime? at}) {
  return NotificationItem(
    id: id,
    businessId: 'b1',
    recipientMemberId: 'm1',
    type: 'low_stock',
    payload: const {},
    createdAt: at ?? DateTime.utc(2026, 1, 1),
    readAt: unread ? null : DateTime.utc(2026, 1, 2),
  );
}

void main() {
  test('mergeNotificationPages prefers unique ids and newest first', () {
    final live = [_item('n2', at: DateTime.utc(2026, 2, 1))];
    final history = [
      _item('n1', at: DateTime.utc(2026, 1, 1)),
      _item('n2', at: DateTime.utc(2026, 2, 1), unread: false),
    ];
    final merged = mergeNotificationPages(live: live, history: history);
    expect(merged.map((n) => n.id).toList(), ['n2', 'n1']);
    expect(merged.first.isUnread, isTrue);
  });
}
