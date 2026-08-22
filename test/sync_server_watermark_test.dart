import 'package:businesssajilo/data/sync/pull/sync_pull_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerWatermarkTracker', () {
    test('tracks max updated_at across rows and pages', () {
      final tracker = ServerWatermarkTracker();
      tracker.observe([
        {'id': 'a', 'updated_at': '2026-08-01T10:00:00Z'},
        {'id': 'b', 'updated_at': '2026-08-01T12:00:00Z'},
      ]);
      tracker.observe([
        {'id': 'c', 'updated_at': '2026-08-01T11:00:00Z'},
      ]);
      expect(
        tracker.watermarkOr(DateTime.utc(2020)),
        DateTime.parse('2026-08-01T12:00:00Z'),
      );
    });

    test('falls back to created_at when updated_at missing', () {
      final tracker = ServerWatermarkTracker();
      tracker.observe([
        {'id': 'a', 'created_at': '2026-07-05T09:00:00Z'},
      ]);
      expect(
        tracker.watermarkOr(DateTime.utc(2020)),
        DateTime.parse('2026-07-05T09:00:00Z'),
      );
    });

    test('falls back to provided fallback when no rows observed', () {
      final tracker = ServerWatermarkTracker();
      final fallback = DateTime.utc(2026, 8, 1);
      expect(tracker.watermarkOr(fallback), fallback);
    });

    test('ignores rows with null/blank/unparseable timestamps', () {
      final tracker = ServerWatermarkTracker();
      tracker.observe([
        {'id': 'a'},
        {'id': 'b', 'updated_at': ''},
        {'id': 'c', 'updated_at': 'not-a-date'},
        {'id': 'ok', 'updated_at': '2026-06-01T00:00:00Z'},
      ]);
      expect(
        tracker.watermarkOr(DateTime.utc(2020)),
        DateTime.parse('2026-06-01T00:00:00Z'),
      );
    });

    test('device clock ahead of server does not skip rows (regression)', () {
      // The bug this fixes: watermark used client wall clock, so a device
      // clock ahead of the DB skipped server rows until they changed again.
      final tracker = ServerWatermarkTracker();
      final skewedDeviceNow = DateTime.utc(2027); // far in the future
      tracker.observe([
        {'id': 'x', 'updated_at': '2026-08-20T00:00:00Z'}, // server time
      ]);
      final wm = tracker.watermarkOr(skewedDeviceNow);
      expect(wm, DateTime.parse('2026-08-20T00:00:00Z'));
      expect(wm.isBefore(skewedDeviceNow), isTrue);
    });
  });
}
