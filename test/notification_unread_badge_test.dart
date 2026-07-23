import 'package:businesssajilo/features/notifications/providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
