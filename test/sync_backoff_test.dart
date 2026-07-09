import 'package:businesssajilo/data/sync/sync_backoff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('backoffForAttempts', () {
    test('returns zero for attempts <= 0', () {
      expect(backoffForAttempts(0), Duration.zero);
      expect(backoffForAttempts(-1), Duration.zero);
    });

    test('doubles for early attempts', () {
      expect(backoffForAttempts(1), const Duration(seconds: 2));
      expect(backoffForAttempts(2), const Duration(seconds: 4));
    });

    test('caps at syncMaxBackoff for large attempts', () {
      expect(backoffForAttempts(9), syncMaxBackoff);
      expect(backoffForAttempts(20), syncMaxBackoff);
      expect(backoffForAttempts(8), const Duration(seconds: 256));
      expect(backoffForAttempts(8) < syncMaxBackoff, isTrue);
    });
  });
}
