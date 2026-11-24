import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:businesssajilo/core/export/csv_writer.dart';
import 'package:businesssajilo/core/import/simple_xlsx.dart';
import 'package:businesssajilo/core/logging/log_redactor.dart';
import 'package:businesssajilo/core/notifications/notification_payload.dart';
import 'package:businesssajilo/core/notifications/notification_target.dart';
import 'package:businesssajilo/core/router/role_routes.dart';
import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/remote/postgrest_filter.dart';
import 'package:businesssajilo/data/sync/sync_service.dart';
import 'package:businesssajilo/data/sync/syncing_payments_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/notification_item.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('LogRedactor', () {
    test('redacts JWTs, auth headers, secrets, emails, and phones', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIn0.'
          'dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';
      final raw =
          'Authorization: Bearer superSecretToken123 '
          'jwt=$jwt apikey=sb_secret_abc123 '
          'user=owner@example.com phone=+9779841234567';
      final redacted = LogRedactor.redactText(raw);

      expect(redacted, isNot(contains('superSecretToken123')));
      expect(redacted, isNot(contains('eyJhbGci')));
      expect(redacted, isNot(contains('sb_secret_abc123')));
      expect(redacted, isNot(contains('owner@example.com')));
      expect(redacted, isNot(contains('9841234567')));
      expect(redacted, contains('[REDACTED_JWT]'));
      expect(redacted, contains('Bearer [REDACTED]'));
      expect(redacted, contains('[REDACTED_EMAIL]'));
      expect(redacted, contains('[REDACTED_PHONE]'));
    });

    test('redacts sensitive map keys and nested values', () {
      final out = LogRedactor.redactMap({
        'phase': 'sync_push',
        'password': 'my-password',
        'nested': {
          'access_token': 'tok-12345678',
          'detail': 'Contact ram@shop.np or 9812345678',
        },
        'count': 3,
      });

      expect(out['phase'], 'sync_push');
      expect(out['password'], '[REDACTED]');
      expect(out['count'], 3);
      final nested = out['nested'] as Map<String, dynamic>;
      expect(nested['access_token'], '[REDACTED]');
      expect(nested['detail'], isNot(contains('ram@shop.np')));
      expect(nested['detail'], isNot(contains('9812345678')));
    });
  });

  group('sanitizePostgrestOrIlikeQuery', () {
    test('strips PostgREST filter syntax characters while keeping text', () {
      expect(
        sanitizePostgrestOrIlikeQuery('tea),is_active.eq.false,name.ilike.(x'),
        'teais_active.eq.falsename.ilike.x'.replaceAll('_', ''),
      );
      expect(sanitizePostgrestOrIlikeQuery('  चिया 500g  '), 'चिया 500g');
      expect(sanitizePostgrestOrIlikeQuery('a,b(c)%_*'), 'abc');
    });
  });

  group('Notification deep-link validation', () {
    NotificationItem makeItem(String type, Map<String, dynamic> payload) =>
        NotificationItem(
          id: 'n1',
          businessId: 'b1',
          recipientMemberId: 'm1',
          type: type,
          payload: payload,
        );

    test('rejects path traversal, query injection, and non-string IDs', () {
      final traversal = NotificationPayloadIds.fromItem(
        makeItem('order_placed', {'order_id': '../owner/customers/123'}),
      );
      expect(traversal.orderId, isNull);

      final queryInject = NotificationPayloadIds.fromItem(
        makeItem('payment_recorded', {'bill_id': 'b1?admin=1'}),
      );
      expect(queryInject.billId, isNull);

      final nonString = NotificationPayloadIds.fromItem(
        makeItem('low_stock', {'product_id': 12345}),
      );
      expect(nonString.productId, isNull);

      expect(
        resolveNotificationTarget(
          makeItem('order_placed', {'order_id': '../customers/c1'}),
          role: Role.warehouse,
        ),
        isA<NotificationNonNavigable>(),
      );
    });

    test('accepts standard UUIDs and short alphanumeric IDs', () {
      final valid = NotificationPayloadIds.fromItem(
        makeItem('payment_recorded', {
          'bill_id': '550e8400-e29b-41d4-a716-446655440000',
        }),
      );
      expect(valid.billId, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('pathAllowedForRole blocks warehouse from /quote/ deep links', () {
      expect(pathAllowedForRole('/quote/q1', Role.warehouse), isFalse);
      expect(pathAllowedForRole('/quote/q1', Role.owner), isTrue);
      expect(pathAllowedForRole('/quote/q1', Role.sales), isTrue);
      expect(pathAllowedForRole('/quote/q1', Role.customer), isTrue);
    });
  });

  group('CsvWriter formula neutralization', () {
    const writer = CsvWriter();

    test('prefixes dangerous formula starters while preserving signed NPR', () {
      final csv = writer.build([
        ['=CMD()', '+1+1', '@SUM(A1)', '-SUM(A1)', '-रू 0.01', '-123.45'],
      ]);
      expect(csv, contains("'=CMD()"));
      expect(csv, contains("'+1+1"));
      expect(csv, contains("'@SUM(A1)"));
      expect(csv, contains("'-SUM(A1)"));
      expect(csv, contains(',-रू 0.01,'));
      expect(csv, contains(',-123.45'));
      expect(csv, isNot(contains("'-रू 0.01")));
      expect(csv, isNot(contains("'-123.45")));
    });
  });

  group('SimpleXlsx DoS bounds', () {
    test('rejects worksheets with out-of-bounds cell references', () {
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'xl/worksheets/sheet1.xml',
            '<?xml version="1.0" encoding="UTF-8"?>'
                '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
                '<sheetData><row r="1048576"><c r="XFD1048576"><v>1</v></c></row></sheetData>'
                '</worksheet>',
          ),
        );
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      expect(() => const SimpleXlsx().decode(bytes), throwsFormatException);
    });
  });

  group('AppDatabase v6 indexes & SQL aggregates', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('creates performance indexes on local tables', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'idx_%'",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll(<String>[
          'idx_sync_queue_status_created',
          'idx_sync_queue_entity',
          'idx_local_products_active_name',
          'idx_local_customers_shop_name',
          'idx_local_customers_balance_due',
          'idx_local_bills_created_at',
          'idx_local_bills_customer_status',
          'idx_local_bill_items_bill_id',
          'idx_local_payments_customer_created',
          'idx_local_payments_bill_id',
          'idx_local_stock_movements_product_created',
        ]),
      );
    });

    test('SQL count and sum aggregates match expected values', () async {
      await db.enqueue(entityType: 'bill', entityId: 'b1', payload: const {});
      await db.enqueue(entityType: 'bill', entityId: 'b2', payload: const {});
      await db.customStatement(
        "UPDATE sync_queue SET status = 'failed' WHERE entity_id = 'b2'",
      );

      expect(await db.pendingCount(), 2);
      expect(await db.retryableCount(), 1);
      expect(await db.failedCount(), 1);

      final now = DateTime.utc(2026, 1, 1);
      await db
          .into(db.localCustomers)
          .insert(
            LocalCustomersCompanion.insert(
              id: 'c-due',
              businessId: 'biz',
              memberId: 'm1',
              shopName: 'Due Shop',
              balanceDue: const Value(15000),
              updatedAt: now,
            ),
          );
      await db
          .into(db.localCustomers)
          .insert(
            LocalCustomersCompanion.insert(
              id: 'c-credit',
              businessId: 'biz',
              memberId: 'm2',
              shopName: 'Credit Shop',
              balanceDue: const Value(-5000),
              updatedAt: now,
            ),
          );

      final sync = SyncService(
        db: db,
        client: SupabaseClient('http://localhost', 'anon'),
      );
      final payments = SyncingPaymentsRepository(
        db: db,
        sync: sync,
        businessId: 'biz',
      );
      expect(await payments.totalDues(), 15000);
      expect(await payments.totalReceivedForBill('b1'), 0);

      await db
          .into(db.localPayments)
          .insert(
            LocalPaymentsCompanion.insert(
              id: 'p1',
              businessId: 'biz',
              customerId: 'c-due',
              billId: const Value('b1'),
              amount: 4000,
              method: 'cash',
              receivedBy: 'm-staff',
            ),
          );
      await db
          .into(db.localPayments)
          .insert(
            LocalPaymentsCompanion.insert(
              id: 'p2',
              businessId: 'biz',
              customerId: 'c-due',
              billId: const Value('b1'),
              amount: 2500,
              method: 'cash',
              receivedBy: 'm-staff',
            ),
          );
      expect(await payments.totalReceivedForBill('b1'), 6500);
    });
  });
}
