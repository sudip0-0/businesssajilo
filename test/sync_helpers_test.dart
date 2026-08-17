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

  group('mapRpcObject', () {
    test('accepts Map<dynamic, dynamic> from jsonDecode', () {
      final raw = <dynamic, dynamic>{
        'bill': {'bill_no': 'BS-0001', 'status': 'due'},
        'created': true,
      };
      final mapped = mapRpcObject(raw);
      expect(mapped['created'], isTrue);
      expect((mapped['bill'] as Map)['bill_no'], 'BS-0001');
    });

    test('rejects non-maps', () {
      expect(() => mapRpcObject(123), throwsFormatException);
    });

    test('accepts json string and a single-element list', () {
      expect(mapRpcObject('{"created":true}')['created'], isTrue);
      expect(
        mapRpcObject([
          {'created': true},
        ])['created'],
        isTrue,
      );
    });
  });

  group('sanitizeBillPayload', () {
    test('turns empty uuid strings into null', () {
      final sanitized = sanitizeBillPayload({
        'customer_id': '  ',
        'order_id': '',
        'items': [
          {'product_id': '', 'qty': 1},
        ],
      });
      expect(sanitized['customer_id'], isNull);
      expect(sanitized['order_id'], isNull);
      expect((sanitized['items'] as List).first['product_id'], isNull);
    });
  });

  group('withCustomerSnapshot', () {
    test('fills shop name and phone when missing', () {
      final tagged = withCustomerSnapshot(
        {'customer_id': 'c1'},
        shopName: 'Ram Store',
        phone: '+9779811111111',
      );
      expect(tagged['customer_shop_name'], 'Ram Store');
      expect(tagged['customer_phone'], '+9779811111111');
    });

    test('does not overwrite an existing snapshot', () {
      final tagged = withCustomerSnapshot(
        {'customer_shop_name': 'Kept', 'customer_phone': '1'},
        shopName: 'Other',
        phone: '2',
      );
      expect(tagged['customer_shop_name'], 'Kept');
      expect(tagged['customer_phone'], '1');
    });
  });

  group('syncCompletionOutcome', () {
    test('reports all_synced when the queue is empty', () {
      expect(
        syncCompletionOutcome(retryableCount: 0, failedCount: 0),
        'all_synced',
      );
    });

    test('reports pending retryable items', () {
      expect(
        syncCompletionOutcome(retryableCount: 2, failedCount: 0),
        'pending_retryable_remain',
      );
    });

    test('reports terminal failures', () {
      expect(
        syncCompletionOutcome(retryableCount: 0, failedCount: 1),
        'terminal_failures_remain',
      );
    });
  });

  group('extractSyncErrorDetail', () {
    test('extracts Postgrest message without stack traces', () {
      expect(
        extractSyncErrorDetail(
          'PostgrestException(message: customer not found, code: P0001)',
        ),
        'customer not found',
      );
    });

    test('drops URLs and tokens', () {
      expect(
        extractSyncErrorDetail('Bearer abc at https://example.com'),
        isNull,
      );
    });
  });

  group('stampOccurredAt', () {
    test('adds created_at when missing', () {
      final stamped = stampOccurredAt({
        'id': 'b1',
      }, DateTime.utc(2026, 8, 16, 4, 15));
      expect(stamped['created_at'], '2026-08-16T04:15:00.000Z');
    });

    test('does not overwrite an existing created_at', () {
      final stamped = stampOccurredAt({
        'created_at': '2026-08-15T00:00:00.000Z',
      }, DateTime.utc(2026, 8, 16));
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
