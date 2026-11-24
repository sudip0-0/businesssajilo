import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';

part 'app_database.g.dart';

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get dependsOnId => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Generic key-value store for sync metadata (e.g. active business id).
class SyncMeta extends Table {
  TextColumn get metaKey => text()();
  TextColumn get metaValue => text()();

  @override
  Set<Column> get primaryKey => {metaKey};
}

class SyncWatermarks extends Table {
  TextColumn get remoteTable => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {remoteTable};
}

class DeviceMeta extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text()();
  TextColumn get devicePrefix => text()();
  IntColumn get localBillSeq => integer().withDefault(const Constant(0))();
}

class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get nameNp => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get unit => text()();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get referencePrice => integer().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(0))();
  IntColumn get stockCached => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get memberId => text()();
  TextColumn get shopName => text()();
  TextColumn get contactName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  IntColumn get balanceDue => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalBills extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get orderId => text().nullable()();
  TextColumn get billNo => text()();
  TextColumn get provisionalBillNo => text().nullable()();
  TextColumn get devicePrefix => text().nullable()();
  IntColumn get itemsTotal => integer().withDefault(const Constant(0))();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  IntColumn get grandTotal => integer().withDefault(const Constant(0))();
  TextColumn get status => text()();
  TextColumn get createdBy => text()();
  TextColumn get customerShopName => text().nullable()();
  TextColumn get referenceNote => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalBillItems extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text()();
  TextColumn get productId => text()();
  TextColumn get nameSnapshot => text()();
  IntColumn get qty => integer()();
  IntColumn get rate => integer().withDefault(const Constant(0))();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  IntColumn get lineTotal => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalPayments extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get customerId => text()();
  TextColumn get billId => text().nullable()();
  IntColumn get amount => integer()();
  TextColumn get method => text()();
  TextColumn get refNote => text().nullable()();
  TextColumn get receivedBy => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalStockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get productId => text()();
  TextColumn get type => text()();
  IntColumn get qtyDelta => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get refBillId => text().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get createdByName => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    SyncQueue,
    SyncMeta,
    SyncWatermarks,
    DeviceMeta,
    LocalProducts,
    LocalCustomers,
    LocalBills,
    LocalBillItems,
    LocalPayments,
    LocalStockMovements,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.forTesting(super.executor);

  static String scopedName({
    required String businessId,
    required String memberId,
    required Role role,
  }) {
    final scope = jsonEncode([businessId, memberId, role.name]);
    final id = const Uuid().v5(Namespace.url.value, 'businesssajilo:$scope');
    return 'businesssajilo_$id';
  }

  factory AppDatabase.open({
    required String businessId,
    required String memberId,
    required Role role,
  }) => AppDatabase(
    driftDatabase(
      name: scopedName(businessId: businessId, memberId: memberId, role: role),
    ),
  );

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(syncMeta);
        await m.addColumn(syncQueue, syncQueue.nextAttemptAt);
      }
      if (from < 3) {
        // Categories were removed; drop the local table and let
        // TableMigration drop the product category columns.
        await m.deleteTable('local_categories');
        await m.alterTable(TableMigration(localProducts));
      }
      if (from < 4) {
        await m.addColumn(localStockMovements, localStockMovements.refBillId);
      }
      if (from < 5) {
        await m.addColumn(localBills, localBills.referenceNote);
      }
      if (from < 6) {
        await _createIndexes();
      }
    },
  );

  Future<void> _createIndexes() async {
    const statements = <String>[
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status_created '
          'ON sync_queue (status, created_at, id)',
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_entity '
          'ON sync_queue (entity_type, entity_id, status)',
      'CREATE INDEX IF NOT EXISTS idx_local_products_active_name '
          'ON local_products (is_active, name)',
      'CREATE INDEX IF NOT EXISTS idx_local_customers_shop_name '
          'ON local_customers (shop_name)',
      'CREATE INDEX IF NOT EXISTS idx_local_customers_balance_due '
          'ON local_customers (balance_due)',
      'CREATE INDEX IF NOT EXISTS idx_local_customers_created_at '
          'ON local_customers (created_at)',
      'CREATE INDEX IF NOT EXISTS idx_local_bills_created_at '
          'ON local_bills (created_at)',
      'CREATE INDEX IF NOT EXISTS idx_local_bills_customer_status '
          'ON local_bills (customer_id, status, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_local_bills_status_created '
          'ON local_bills (status, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_local_bills_sync_created '
          'ON local_bills (sync_status, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_local_bill_items_bill_id '
          'ON local_bill_items (bill_id)',
      'CREATE INDEX IF NOT EXISTS idx_local_payments_customer_created '
          'ON local_payments (customer_id, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_local_payments_bill_id '
          'ON local_payments (bill_id)',
      'CREATE INDEX IF NOT EXISTS idx_local_payments_sync_customer '
          'ON local_payments (sync_status, customer_id)',
      'CREATE INDEX IF NOT EXISTS idx_local_stock_movements_product_created '
          'ON local_stock_movements (product_id, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_local_stock_movements_ref_bill '
          'ON local_stock_movements (ref_bill_id)',
    ];
    for (final sql in statements) {
      await customStatement(sql);
    }
  }

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    String? dependsOnId,
  }) async {
    await into(syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        dependsOnId: Value(dependsOnId),
        payloadJson: jsonEncode(payload),
      ),
    );
  }

  Future<List<SyncQueueData>> pendingQueue() {
    return (select(syncQueue)
          ..where((q) => q.status.equals('pending'))
          ..orderBy([
            (q) => OrderingTerm.asc(q.createdAt),
            (q) => OrderingTerm.asc(q.id),
          ]))
        .get();
  }

  /// All non-synced items (pending + terminally failed), oldest first.
  Future<List<SyncQueueData>> unsyncedQueue() {
    return (select(syncQueue)
          ..where((q) => q.status.equals('pending') | q.status.equals('failed'))
          ..orderBy([
            (q) => OrderingTerm.asc(q.createdAt),
            (q) => OrderingTerm.asc(q.id),
          ]))
        .get();
  }

  /// Watches the non-synced queue for reactive UI.
  Stream<List<SyncQueueData>> watchUnsyncedQueue() {
    return (select(syncQueue)
          ..where((q) => q.status.equals('pending') | q.status.equals('failed'))
          ..orderBy([
            (q) => OrderingTerm.asc(q.createdAt),
            (q) => OrderingTerm.asc(q.id),
          ]))
        .watch();
  }

  /// Unsynced items shown in the badge (pending + terminal failures).
  Future<int> pendingCount() async {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([count])
      ..where(
        syncQueue.status.equals('pending') | syncQueue.status.equals('failed'),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Automatically retryable queue items only (excludes terminal `failed`).
  Future<int> retryableCount() async {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([count])
      ..where(syncQueue.status.equals('pending'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> failedCount() async {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([count])
      ..where(syncQueue.status.equals('failed'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Marks queue rows for [entityId] synced (pull found the remote row).
  Future<void> markQueueSyncedForEntity(
    String entityId, {
    required String entityType,
  }) async {
    await (update(syncQueue)..where(
          (q) =>
              q.entityId.equals(entityId) &
              q.entityType.equals(entityType) &
              (q.status.equals('pending') | q.status.equals('failed')),
        ))
        .write(const SyncQueueCompanion(status: Value('synced')));
  }

  /// Resets terminally failed items so they get retried from scratch.
  /// When [queueRowId] is set, only that row is reset.
  Future<void> retryFailed({int? queueRowId}) async {
    final rows =
        await (select(syncQueue)..where((q) {
              final failed = q.status.equals('failed');
              if (queueRowId == null) return failed;
              return failed & q.id.equals(queueRowId);
            }))
            .get();
    for (final row in rows) {
      await (update(syncQueue)..where((q) => q.id.equals(row.id))).write(
        const SyncQueueCompanion(
          status: Value('pending'),
          attempts: Value(0),
          nextAttemptAt: Value(null),
          lastError: Value(null),
        ),
      );
      await setLocalEntitySyncStatus(row.entityType, row.entityId, 'pending');
    }
  }

  Future<void> setLocalEntitySyncStatus(
    String entityType,
    String entityId,
    String status,
  ) async {
    switch (entityType) {
      case 'bill':
        await (update(localBills)..where((b) => b.id.equals(entityId))).write(
          LocalBillsCompanion(syncStatus: Value(status)),
        );
      case 'payment':
        await (update(localPayments)..where((p) => p.id.equals(entityId)))
            .write(LocalPaymentsCompanion(syncStatus: Value(status)));
      case 'stock_movement':
        await (update(localStockMovements)..where((m) => m.id.equals(entityId)))
            .write(LocalStockMovementsCompanion(syncStatus: Value(status)));
    }
  }

  /// Deletes successfully synced queue rows older than [olderThan].
  Future<int> pruneSyncedQueue({
    Duration olderThan = const Duration(days: 7),
  }) async {
    final cutoff = DateTime.now().toUtc().subtract(olderThan);
    return (delete(syncQueue)..where(
          (q) =>
              q.status.equals('synced') &
              q.createdAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  Future<DateTime?> watermark(String remoteTable) async {
    final row = await (select(
      syncWatermarks,
    )..where((w) => w.remoteTable.equals(remoteTable))).getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> setWatermark(String remoteTable, DateTime at) async {
    await into(syncWatermarks).insertOnConflictUpdate(
      SyncWatermarksCompanion.insert(
        remoteTable: remoteTable,
        lastSyncedAt: at,
      ),
    );
  }

  Future<String?> metaValue(String key) async {
    final row = await (select(
      syncMeta,
    )..where((m) => m.metaKey.equals(key))).getSingleOrNull();
    return row?.metaValue;
  }

  Future<void> setMetaValue(String key, String value) async {
    await into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(metaKey: key, metaValue: value),
    );
  }

  /// Wipes every locally cached row, watermark, and queued mutation.
  Future<void> wipeAllLocalData() async {
    await transaction(() async {
      await delete(syncMeta).go();
      await delete(syncQueue).go();
      await delete(syncWatermarks).go();
      await delete(localProducts).go();
      await delete(localCustomers).go();
      await delete(localBills).go();
      await delete(localBillItems).go();
      await delete(localPayments).go();
      await delete(localStockMovements).go();
      await delete(deviceMeta).go();
    });
  }

  /// Ensures the local cache belongs to [businessId]; wipes stale tenant data.
  /// Returns true if a wipe happened.
  Future<bool> prepareForBusiness(
    String businessId, {
    bool allowWipe = false,
  }) async {
    const key = 'business_id';
    final stored = await metaValue(key);
    if (stored == businessId) return false;
    if (!allowWipe) {
      for (final table in allTables) {
        if ((await (select(table)..limit(1)).get()).isNotEmpty) {
          throw StateError(
            'Unverified local cache retained; use a scoped database',
          );
        }
      }
    }
    if (stored != null) {
      await wipeAllLocalData();
    }
    await setMetaValue(key, businessId);
    return stored != null;
  }

  Future<DeviceMetaData> ensureDeviceMeta(String deviceId) async {
    final existing = await select(deviceMeta).getSingleOrNull();
    if (existing != null) return existing;

    final prefixNum = deviceId.hashCode.abs() % 99 + 1;
    await into(deviceMeta).insert(
      DeviceMetaCompanion.insert(
        deviceId: deviceId,
        devicePrefix: 'D$prefixNum',
      ),
    );
    return (await select(deviceMeta).getSingle());
  }

  Future<String> nextProvisionalBillNo() async {
    final meta = await select(deviceMeta).getSingle();
    final nextSeq = meta.localBillSeq + 1;
    await (update(deviceMeta)..where((m) => m.id.equals(meta.id))).write(
      DeviceMetaCompanion(localBillSeq: Value(nextSeq)),
    );
    return '${meta.devicePrefix}-$nextSeq';
  }
}
