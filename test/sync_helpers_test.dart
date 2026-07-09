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
}
