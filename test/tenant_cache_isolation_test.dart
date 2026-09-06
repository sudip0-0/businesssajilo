import 'dart:io';

import 'package:businesssajilo/data/local/legacy_cache_recovery.dart';
import 'package:businesssajilo/data/local/legacy_cache_files_io.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'readonly snapshot stays coherent across an uncommitted writer',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bs-snapshot-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/legacy.sqlite');
      final writer = sqlite.sqlite3.open(file.path);
      addTearDown(writer.close);
      writer.execute('PRAGMA journal_mode = WAL');
      writer.execute('PRAGMA user_version = 1');
      writer.execute(
        'CREATE TABLE amounts (id TEXT PRIMARY KEY, amount INTEGER)',
      );
      writer.execute(
        "INSERT INTO amounts VALUES ('owned', 50), ('foreign', 900)",
      );
      writer.execute('BEGIN IMMEDIATE');
      writer.execute("UPDATE amounts SET amount = 75 WHERE id = 'owned'");
      final wal = File('${file.path}-wal');
      final before = await file.readAsBytes();
      final beforeWal = await wal.readAsBytes();
      await IOOverrides.runZoned(
        () => withLegacySnapshot(file.path, (snapshot) async {
          expect(
            snapshot.select('PRAGMA busy_timeout').single.values.single,
            1000,
          );
          expect(
            snapshot.select('PRAGMA user_version').single.values.single,
            1,
          );
          expect(
            snapshot.select('SELECT amount FROM amounts WHERE id = ?', [
              'owned',
            ]).single['amount'],
            50,
          );
          expect(
            () => snapshot.select(
              "UPDATE amounts SET amount = 0 RETURNING amount",
            ),
            throwsA(isA<sqlite.SqliteException>()),
          );
          expect(
            () => snapshot.select('PRAGMA user_version = 2'),
            throwsA(isA<sqlite.SqliteException>()),
          );
          expect(await file.readAsBytes(), before);
          expect(await wal.readAsBytes(), beforeWal);
          writer.execute('COMMIT');
          final committed = await file.readAsBytes();
          final committedWal = await wal.readAsBytes();
          await Future<void>.delayed(Duration.zero);
          expect(
            snapshot.select('SELECT amount FROM amounts WHERE id = ?', [
              'owned',
            ]).single['amount'],
            50,
          );
          expect(await file.readAsBytes(), committed);
          expect(await wal.readAsBytes(), committedWal);
        }),
        getSystemTempDirectory: () =>
            throw StateError('Recovery must not copy a temp DB'),
      );
      await withLegacySnapshot(file.path, (snapshot) async {
        expect(
          snapshot.select('SELECT amount FROM amounts WHERE id = ?', [
            'owned',
          ]).single['amount'],
          75,
        );
      });
      expect(writer.userVersion, 1);
      expect(
        directory.listSync().map(
          (entry) => entry.path.split(Platform.pathSeparator).last,
        ),
        unorderedEquals([
          'legacy.sqlite',
          'legacy.sqlite-wal',
          'legacy.sqlite-shm',
        ]),
      );
    },
  );

  test(
    'readonly snapshot fails within its busy timeout and releases locks',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bs-locked-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/legacy.sqlite');
      final writer = sqlite.sqlite3.open(file.path);
      addTearDown(writer.close);
      writer.execute('CREATE TABLE fixture (id INTEGER)');
      writer.execute('BEGIN EXCLUSIVE');
      final elapsed = Stopwatch()..start();
      await expectLater(
        withLegacySnapshot(
          file.path,
          (_) async => fail('Locked source was read'),
        ),
        throwsA(isA<sqlite.SqliteException>()),
      );
      expect(elapsed.elapsed, lessThan(const Duration(seconds: 5)));
      writer.execute('ROLLBACK');
      await expectLater(
        withLegacySnapshot(file.path, (_) async => throw StateError('abort')),
        throwsStateError,
      );
      writer.execute('BEGIN EXCLUSIVE');
      writer.execute('ROLLBACK');
    },
  );

  for (final role in [Role.owner, Role.sales, Role.warehouse]) {
    test(
      'legacy recovery copies only owned permitted work ($role) without changing source',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'bs-recovery-test-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final sourceFile = File('${directory.path}/legacy.sqlite');
        final source = AppDatabase.forTesting(NativeDatabase(sourceFile));
        for (final billId in ['owned', 'other-member']) {
          await source
              .into(source.localPayments)
              .insert(
                LocalPaymentsCompanion.insert(
                  id: 'dependent-$billId',
                  businessId: 'business',
                  customerId: 'customer',
                  billId: Value(billId),
                  amount: 5,
                  method: 'cash',
                  receivedBy: 'member',
                ),
              );
          await source.enqueue(
            entityType: 'payment',
            entityId: 'dependent-$billId',
            dependsOnId: billId,
            payload: {
              'id': 'dependent-$billId',
              'customer_id': 'customer',
              'bill_id': billId,
              'amount': 5,
              'method': 'cash',
            },
          );
        }
        for (final id in [
          'owned',
          'other-member',
          'other-business',
          'ambiguous',
          'paid',
          'foreign-payment',
          'duplicate',
        ]) {
          final business = id == 'other-business'
              ? 'other-business'
              : 'business';
          final member = id == 'other-member' ? 'other-member' : 'member';
          final paid = id == 'paid' || id == 'foreign-payment';
          await source
              .into(source.localBills)
              .insert(
                LocalBillsCompanion.insert(
                  id: id,
                  businessId: business,
                  billNo: 'D1-$id',
                  status: paid ? 'paid' : 'due',
                  createdBy: member,
                  customerId: const Value('customer'),
                  grandTotal: const Value(100),
                ),
              );
          await source.enqueue(
            entityType: 'bill',
            entityId: id,
            payload: {
              'id': id == 'ambiguous' ? 'wrong-id' : id,
              'status': paid ? 'paid' : 'due',
              if (paid)
                'payment': {
                  'id': 'embedded-$id',
                  'amount': 100,
                  'method': 'cash',
                },
              'customer_id': 'customer',
              'items': [
                {
                  'product_id': 'product',
                  'name_snapshot': 'Snapshot',
                  'qty': 1,
                  'rate': 100,
                  'discount': 0,
                },
              ],
            },
          );
          await source
              .into(source.localBillItems)
              .insert(
                LocalBillItemsCompanion.insert(
                  id: '$id-item',
                  billId: id,
                  productId: 'product',
                  nameSnapshot: 'Snapshot',
                  qty: 1,
                  rate: const Value(100),
                  lineTotal: const Value(100),
                ),
              );
        }
        for (final id in ['paid', 'foreign-payment']) {
          await source
              .into(source.localPayments)
              .insert(
                LocalPaymentsCompanion.insert(
                  id: 'embedded-$id',
                  businessId: 'business',
                  customerId: 'customer',
                  billId: Value(id),
                  amount: 100,
                  method: 'cash',
                  receivedBy: id == 'paid' ? 'member' : 'other-member',
                ),
              );
        }
        await source.enqueue(
          entityType: 'bill',
          entityId: 'duplicate',
          payload: {'id': 'duplicate'},
        );
        await source
            .into(source.localStockMovements)
            .insert(
              LocalStockMovementsCompanion.insert(
                id: 'bill-mirror',
                businessId: 'business',
                productId: 'product',
                type: 'dispatch',
                qtyDelta: -1,
                refBillId: const Value('owned'),
                createdBy: 'member',
              ),
            );
        await source
            .into(source.localCustomers)
            .insert(
              LocalCustomersCompanion.insert(
                id: 'customer',
                businessId: 'business',
                memberId: 'customer-member',
                shopName: 'Shop',
                balanceDue: const Value(999999),
                openingBalance: const Value(888888),
                updatedAt: DateTime.utc(2026),
              ),
            );
        await source
            .into(source.localPayments)
            .insert(
              LocalPaymentsCompanion.insert(
                id: 'payment',
                businessId: 'business',
                customerId: 'customer',
                amount: 25,
                method: 'cash',
                receivedBy: 'member',
              ),
            );
        await source.enqueue(
          entityType: 'payment',
          entityId: 'payment',
          payload: {
            'id': 'payment',
            'customer_id': 'customer',
            'amount': 25,
            'method': 'cash',
          },
        );
        await source
            .into(source.localStockMovements)
            .insert(
              LocalStockMovementsCompanion.insert(
                id: 'movement',
                businessId: 'business',
                productId: 'product',
                type: 'in',
                qtyDelta: 2,
                createdBy: 'member',
              ),
            );
        await source.enqueue(
          entityType: 'stock_movement',
          entityId: 'movement',
          payload: {
            'id': 'movement',
            'business_id': 'business',
            'product_id': 'product',
            'type': 'in',
            'qty_delta': 2,
            'created_by': 'member',
          },
        );
        await source.enqueue(
          entityType: 'unknown',
          entityId: 'unknown',
          payload: {'id': 'unknown'},
        );
        await source.customStatement('PRAGMA user_version = 1');
        await source.close();
        final before = await sourceFile.readAsBytes();
        final targetFile = File('${directory.path}/target.sqlite');
        var target = AppDatabase.forTesting(NativeDatabase(targetFile));
        Future<void> recover() => recoverLegacyCache(
          db: target,
          sourcePath: sourceFile.path,
          businessId: 'business',
          memberId: 'member',
          role: role,
        );
        await recover();
        expect(
          (await target.select(target.localBills).get()).map((b) => b.id),
          role == Role.warehouse ? ['owned'] : ['owned', 'paid'],
        );
        expect(
          (await target.select(target.localBillItems).get()).map((i) => i.id),
          role == Role.warehouse ? ['owned-item'] : ['owned-item', 'paid-item'],
        );
        expect(
          (await target.select(target.localPayments).get()).length,
          role == Role.warehouse ? 0 : 3,
        );
        expect(
          (await target.select(target.localStockMovements).get()).length,
          role == Role.sales ? 1 : 2,
        );
        final identity = await target.select(target.localCustomers).getSingle();
        expect(identity.openingBalance, 0);
        expect(identity.balanceDue, role == Role.warehouse ? 0 : 70);
        if (role != Role.warehouse) {
          final queue = await target.pendingQueue();
          expect(
            queue.indexWhere((q) => q.entityId == 'owned'),
            lessThan(queue.indexWhere((q) => q.entityId == 'dependent-owned')),
          );
          expect(
            queue.any((q) => q.entityId == 'dependent-other-member'),
            isFalse,
          );
        }
        expect(await target.metaValue(legacyRecoveryNoticeKey), 'retained');
        final count = await target.pendingCount();
        await target.close();
        target = AppDatabase.forTesting(NativeDatabase(targetFile));
        await recover();
        expect(await target.pendingCount(), count);
        await target
            .update(target.syncQueue)
            .write(const SyncQueueCompanion(status: Value('synced')));
        await target.pruneSyncedQueue(olderThan: Duration.zero);
        await recover();
        expect(await target.pendingCount(), 0);
        await target.close();
        expect(await sourceFile.readAsBytes(), before);
      },
    );
  }

  test(
    'orphan pending rows stay intact and produce a recovery notice',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bs-orphan-recovery-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/legacy.sqlite');
      final source = AppDatabase.forTesting(NativeDatabase(file));
      await source
          .into(source.localPayments)
          .insert(
            LocalPaymentsCompanion.insert(
              id: 'orphan',
              businessId: 'business',
              customerId: 'customer',
              amount: 50,
              method: 'cash',
              receivedBy: 'member',
            ),
          );
      await source.close();
      final before = await file.readAsBytes();
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      await recoverLegacyCache(
        db: target,
        sourcePath: file.path,
        businessId: 'business',
        memberId: 'member',
        role: Role.owner,
      );
      expect(await target.pendingCount(), 0);
      expect(await target.select(target.localPayments).get(), isEmpty);
      expect(await target.metaValue(legacyRecoveryNoticeKey), 'retained');
      expect(await file.readAsBytes(), before);
      await target.close();
    },
  );

  test(
    'recovery includes committed WAL work without altering source files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bs-wal-recovery-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/legacy.sqlite');
      final source = AppDatabase.forTesting(NativeDatabase(file));
      await source.customStatement('PRAGMA journal_mode = WAL');
      await source
          .into(source.localPayments)
          .insert(
            LocalPaymentsCompanion.insert(
              id: 'payment',
              businessId: 'business',
              customerId: 'customer',
              amount: 50,
              method: 'cash',
              receivedBy: 'member',
            ),
          );
      await source.enqueue(
        entityType: 'payment',
        entityId: 'payment',
        payload: {
          'id': 'payment',
          'customer_id': 'customer',
          'amount': 50,
          'method': 'cash',
        },
      );
      final wal = File('${file.path}-wal');
      final before = await file.readAsBytes();
      final beforeWal = await wal.readAsBytes();
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      await recoverLegacyCache(
        db: target,
        sourcePath: file.path,
        businessId: 'business',
        memberId: 'member',
        role: Role.owner,
      );
      expect((await target.pendingQueue()).single.entityId, 'payment');
      expect(await file.readAsBytes(), before);
      expect(await wal.readAsBytes(), beforeWal);
      await target.close();
      await source.close();
    },
  );

  test(
    'recovery pins queue and entity rows before a concurrent commit',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bs-commit-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/legacy.sqlite');
      final source = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(source.close);
      await source.customStatement('PRAGMA journal_mode = WAL');
      await source
          .into(source.localPayments)
          .insert(
            LocalPaymentsCompanion.insert(
              id: 'payment',
              businessId: 'business',
              customerId: 'customer',
              amount: 50,
              method: 'cash',
              receivedBy: 'member',
            ),
          );
      await source.enqueue(
        entityType: 'payment',
        entityId: 'payment',
        payload: {
          'id': 'payment',
          'customer_id': 'customer',
          'amount': 50,
          'method': 'cash',
        },
      );
      final writer = sqlite.sqlite3.open(file.path);
      addTearDown(writer.close);
      writer.execute('BEGIN IMMEDIATE');
      writer.execute(
        "UPDATE local_payments SET amount = 75 WHERE id = 'payment'",
      );
      writer.execute(
        "UPDATE sync_queue SET payload_json = replace(payload_json, '50', '75')",
      );
      var committed = false;
      final target = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (_) {
            writer.execute('COMMIT');
            committed = true;
          },
        ),
      );
      addTearDown(target.close);
      Future<void> recover() => recoverLegacyCache(
        db: target,
        sourcePath: file.path,
        businessId: 'business',
        memberId: 'member',
        role: Role.owner,
      );
      await recover();
      expect(committed, isTrue);
      expect(
        (await target.select(target.localPayments).getSingle()).amount,
        50,
      );
      expect((await target.pendingQueue()).single.payloadJson, contains('50'));
      expect(
        (await source.select(source.localPayments).getSingle()).amount,
        75,
      );
      await recover();
      expect(
        (await target.select(target.localPayments).getSingle()).amount,
        50,
      );
      expect(await target.pendingCount(), 1);
    },
  );

  test(
    'startup recovers allowed former-role work and preserves forbidden work',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bs-role-recovery-',
      );
      addTearDown(() => directory.delete(recursive: true));
      AppDatabase open(Role role) => AppDatabase.forTesting(
        NativeDatabase(
          File(
            '${directory.path}/${AppDatabase.scopedName(businessId: 'business', memberId: 'member', role: role)}.sqlite',
          ),
        ),
      );
      final owner = open(Role.owner);
      await owner
          .into(owner.localPayments)
          .insert(
            LocalPaymentsCompanion.insert(
              id: 'payment',
              businessId: 'business',
              customerId: 'customer',
              amount: 50,
              method: 'cash',
              receivedBy: 'member',
            ),
          );
      await owner.enqueue(
        entityType: 'payment',
        entityId: 'payment',
        payload: {
          'id': 'payment',
          'customer_id': 'customer',
          'amount': 50,
          'method': 'cash',
        },
      );
      await owner.close();
      final warehouse = open(Role.warehouse);
      await recoverPreviousCaches(
        db: warehouse,
        businessId: 'business',
        memberId: 'member',
        role: Role.warehouse,
      );
      expect(await warehouse.pendingCount(), 0);
      expect(await warehouse.metaValue(legacyRecoveryNoticeKey), 'retained');
      await warehouse.close();
      final sales = open(Role.sales);
      await recoverPreviousCaches(
        db: sales,
        businessId: 'business',
        memberId: 'member',
        role: Role.sales,
      );
      expect((await sales.pendingQueue()).single.entityId, 'payment');
      await sales.close();
      final restoredOwner = open(Role.owner);
      await recoverPreviousCaches(
        db: restoredOwner,
        businessId: 'business',
        memberId: 'member',
        role: Role.owner,
      );
      expect((await restoredOwner.pendingQueue()).single.entityId, 'payment');
      expect(
        (await restoredOwner.select(restoredOwner.localPayments).get()).length,
        1,
      );
      await restoredOwner.close();
    },
  );

  test(
    'scoped caches isolate accounts and roles and retain work after restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('bs-sync-test-');
      addTearDown(() => directory.delete(recursive: true));
      AppDatabase open(String member, Role role) {
        final name = AppDatabase.scopedName(
          businessId: 'biz-a',
          memberId: member,
          role: role,
        );
        return AppDatabase.forTesting(
          NativeDatabase(File('${directory.path}/$name.sqlite')),
        );
      }

      final legacyFile = File('${directory.path}/businesssajilo_local.sqlite');
      final legacy = AppDatabase.forTesting(NativeDatabase(legacyFile));
      await legacy.enqueue(
        entityType: 'payment',
        entityId: 'legacy-payment',
        payload: {'id': 'legacy-payment'},
      );
      await legacy.close();
      final legacyBytes = await legacyFile.readAsBytes();
      final owner = open('member-a', Role.owner);
      await owner
          .into(owner.localCustomers)
          .insert(
            LocalCustomersCompanion.insert(
              id: 'customer',
              businessId: 'biz-a',
              memberId: 'customer-member',
              shopName: 'Private',
              balanceDue: const Value(500),
              updatedAt: DateTime.utc(2026),
            ),
          );
      await owner.enqueue(
        entityType: 'payment',
        entityId: 'payment',
        payload: {'id': 'payment'},
      );
      await owner.setMetaValue('bootstrap_offset', '200');
      await owner.close();
      for (final scope in [
        ('member-b', Role.owner),
        ('member-a', Role.warehouse),
        ('member-a', Role.sales),
      ]) {
        final other = open(scope.$1, scope.$2);
        expect(await other.select(other.localCustomers).get(), isEmpty);
        expect(await other.pendingQueue(), isEmpty);
        expect(await other.metaValue('bootstrap_offset'), isNull);
        await other.close();
      }
      final restored = open('member-a', Role.owner);
      expect(
        (await restored.select(restored.localCustomers).getSingle()).balanceDue,
        500,
      );
      expect((await restored.pendingQueue()).single.entityId, 'payment');
      expect(await restored.metaValue('bootstrap_offset'), '200');
      await restored.close();
      expect(await legacyFile.readAsBytes(), legacyBytes);
    },
  );

  for (final previousBusiness in [null, 'old-business']) {
    test(
      'unverified legacy cache is retained (business=$previousBusiness)',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        if (previousBusiness != null) {
          await db.prepareForBusiness(previousBusiness);
        }
        await db.enqueue(
          entityType: 'payment',
          entityId: 'pending',
          payload: {'id': 'pending'},
        );
        await db.setMetaValue('bootstrap_offset', '200');
        await expectLater(
          db.prepareForBusiness('new-business'),
          throwsStateError,
        );
        expect((await db.pendingQueue()).single.entityId, 'pending');
        expect(await db.metaValue('business_id'), previousBusiness);
        expect(await db.metaValue('bootstrap_offset'), '200');
      },
    );
  }

  test('wipe clears bootstrap and last success metadata', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.setMetaValue('bootstrap_offset', '200');
    await db.setMetaValue('last_success_at', '2026-01-01');
    await db.wipeAllLocalData();
    expect(await db.select(db.syncMeta).get(), isEmpty);
  });

  test('tenant switch wipes local data, watermarks, and queue', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    // Tenant A populates the cache.
    final wipedA = await db.prepareForBusiness('biz-a');
    expect(wipedA, isFalse);

    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'prod-1',
            businessId: 'biz-a',
            name: 'Widget',
            unit: 'piece',
            updatedAt: DateTime.now().toUtc(),
          ),
        );
    await db
        .into(db.localBills)
        .insert(
          LocalBillsCompanion.insert(
            id: 'bill-1',
            businessId: 'biz-a',
            billNo: 'D1-1',
            status: 'paid',
            createdBy: 'member-a',
          ),
        );
    await db.enqueue(
      entityType: 'bill',
      entityId: 'bill-1',
      payload: {'id': 'bill-1'},
    );
    await db.setWatermark('products', DateTime.now().toUtc());

    // Re-bootstrapping for the SAME tenant must keep everything.
    final wipedSame = await db.prepareForBusiness('biz-a');
    expect(wipedSame, isFalse);
    expect(await db.select(db.localProducts).get(), hasLength(1));
    expect(await db.pendingQueue(), hasLength(1));
    expect(await db.watermark('products'), isNotNull);

    // Switching tenant must wipe rows, queue, and watermarks.
    final wipedB = await db.prepareForBusiness('biz-b', allowWipe: true);
    expect(wipedB, isTrue);
    expect(await db.select(db.localProducts).get(), isEmpty);
    expect(await db.select(db.localBills).get(), isEmpty);
    expect(await db.pendingQueue(), isEmpty);
    expect(await db.watermark('products'), isNull);
    expect(await db.metaValue('business_id'), 'biz-b');

    await db.close();
  });
}
