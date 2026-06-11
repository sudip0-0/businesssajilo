import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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

class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get nameNp => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get categoryId => text().nullable()();
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
  TextColumn get categoryName => text().nullable()();
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
    SyncWatermarks,
    DeviceMeta,
    LocalCategories,
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

  factory AppDatabase.open() =>
      AppDatabase(driftDatabase(name: 'businesssajilo_local'));

  @override
  int get schemaVersion => 1;

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
          ..where((q) => q.status.equals('pending') | q.status.equals('failed'))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  Future<int> pendingCount() async {
    final rows = await (select(syncQueue)
          ..where((q) => q.status.equals('pending') | q.status.equals('failed')))
        .get();
    return rows.length;
  }

  Future<DateTime?> watermark(String remoteTable) async {
    final row = await (select(syncWatermarks)
          ..where((w) => w.remoteTable.equals(remoteTable)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> setWatermark(String remoteTable, DateTime at) async {
    await into(syncWatermarks).insertOnConflictUpdate(
      SyncWatermarksCompanion.insert(remoteTable: remoteTable, lastSyncedAt: at),
    );
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

