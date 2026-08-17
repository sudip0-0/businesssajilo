import 'package:businesssajilo/data/sync/sync_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('truncateSyncError', () {
    test('returns short messages unchanged', () {
      expect(truncateSyncError('boom'), 'boom');
    });

    test('truncates long messages to maxLength', () {
      final long = 'x' * 600;
      final truncated = truncateSyncError(long, maxLength: 500);
      expect(truncated.length, 500);
      expect(truncated, 'x' * 500);
    });
  });

  group('SyncCoalesce', () {
    test('tryEnter claims lock and clears queued', () {
      final c = SyncCoalesce()..queued = true;
      expect(c.tryEnter(), isTrue);
      expect(c.syncing, isTrue);
      expect(c.queued, isFalse);
    });

    test('overlapping request marks queued and does not enter', () {
      final c = SyncCoalesce();
      expect(c.tryEnter(), isTrue);
      expect(c.tryEnter(), isFalse);
      expect(c.queued, isTrue);
      expect(c.shouldRepeat, isTrue);
    });

    test('markQueuedIfBusy only when syncing', () {
      final idle = SyncCoalesce();
      idle.markQueuedIfBusy();
      expect(idle.queued, isFalse);

      final busy = SyncCoalesce()..syncing = true;
      busy.markQueuedIfBusy();
      expect(busy.queued, isTrue);
    });

    test('clearQueued and end reset state for next pass', () {
      final c = SyncCoalesce();
      c.tryEnter();
      c.markQueuedIfBusy();
      c.clearQueued();
      expect(c.shouldRepeat, isFalse);
      c.end();
      expect(c.syncing, isFalse);
      expect(c.tryEnter(), isTrue);
    });
  });

  group('ReachabilityBackoff', () {
    test('steps through 5s, 15s, 30s, then stays at 60s', () {
      final backoff = ReachabilityBackoff();
      expect(backoff.next(), const Duration(seconds: 5));
      expect(backoff.next(), const Duration(seconds: 15));
      expect(backoff.next(), const Duration(seconds: 30));
      expect(backoff.next(), const Duration(seconds: 60));
      expect(backoff.next(), const Duration(seconds: 60));
    });

    test('reset starts the sequence again', () {
      final backoff = ReachabilityBackoff()
        ..next()
        ..next();
      backoff.reset();
      expect(backoff.next(), const Duration(seconds: 5));
    });
  });

  group('stampOccurredAt', () {
    test('adds created_at when missing', () {
      final stamped = stampOccurredAt(
        {'id': 'b1'},
        DateTime.utc(2026, 8, 16, 4, 15),
      );
      expect(stamped['created_at'], '2026-08-16T04:15:00.000Z');
    });

    test('does not overwrite an existing created_at', () {
      final stamped = stampOccurredAt(
        {'created_at': '2026-08-15T00:00:00.000Z'},
        DateTime.utc(2026, 8, 16),
      );
      expect(stamped['created_at'], '2026-08-15T00:00:00.000Z');
    });
  });

  group('preferOccurredAt', () {
    test('keeps the earlier local time', () {
      expect(
        preferOccurredAt(
          local: DateTime.utc(2026, 8, 16),
          remote: DateTime.utc(2026, 8, 17),
        ),
        DateTime.utc(2026, 8, 16),
      );
    });

    test('uses remote when there is no local row', () {
      expect(
        preferOccurredAt(remote: DateTime.utc(2026, 8, 17)),
        DateTime.utc(2026, 8, 17),
      );
    });
  });
}
