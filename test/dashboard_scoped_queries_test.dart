import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/remote/supabase_customers_repository.dart';
import 'package:businesssajilo/data/remote/supabase_products_repository.dart';
import 'package:businesssajilo/data/sync/cached_customers_repository.dart';
import 'package:businesssajilo/data/sync/cached_products_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('listLowStock returns only low-stock products up to limit', () async {
    final now = DateTime.utc(2026, 1, 1);
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'ok',
            businessId: 'biz',
            name: 'Plenty',
            unit: 'pcs',
            lowStockThreshold: const Value(5),
            stockCached: const Value(20),
            updatedAt: now,
          ),
        );
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'low-a',
            businessId: 'biz',
            name: 'Alpha Low',
            unit: 'pcs',
            lowStockThreshold: const Value(10),
            stockCached: const Value(2),
            updatedAt: now,
          ),
        );
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'low-b',
            businessId: 'biz',
            name: 'Beta Low',
            unit: 'pcs',
            lowStockThreshold: const Value(5),
            stockCached: const Value(0),
            updatedAt: now,
          ),
        );
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'low-c',
            businessId: 'biz',
            name: 'Charlie Low',
            unit: 'pcs',
            lowStockThreshold: const Value(3),
            stockCached: const Value(1),
            updatedAt: now,
          ),
        );
    await db
        .into(db.localProducts)
        .insert(
          LocalProductsCompanion.insert(
            id: 'inactive',
            businessId: 'biz',
            name: 'Inactive Low',
            unit: 'pcs',
            lowStockThreshold: const Value(5),
            stockCached: const Value(0),
            isActive: const Value(false),
            updatedAt: now,
          ),
        );

    final repo = CachedProductsRepository(
      db: db,
      remote: SupabaseProductsRepository(null),
    );
    final alerts = await repo.listLowStock(limit: 2);
    expect(alerts, hasLength(2));
    expect(alerts.map((p) => p.id).toList(), ['low-a', 'low-b']);
  });

  test('listRecent returns newest customers first up to limit', () async {
    final older = DateTime.utc(2026, 1, 1);
    final newer = DateTime.utc(2026, 6, 1);
    final newest = DateTime.utc(2026, 7, 1);

    await db
        .into(db.localCustomers)
        .insert(
          LocalCustomersCompanion.insert(
            id: 'c-old',
            businessId: 'biz',
            memberId: 'm1',
            shopName: 'Old Shop',
            updatedAt: older,
            createdAt: Value(older),
          ),
        );
    await db
        .into(db.localCustomers)
        .insert(
          LocalCustomersCompanion.insert(
            id: 'c-mid',
            businessId: 'biz',
            memberId: 'm2',
            shopName: 'Mid Shop',
            updatedAt: newer,
            createdAt: Value(newer),
          ),
        );
    await db
        .into(db.localCustomers)
        .insert(
          LocalCustomersCompanion.insert(
            id: 'c-new',
            businessId: 'biz',
            memberId: 'm3',
            shopName: 'New Shop',
            updatedAt: newest,
            createdAt: Value(newest),
          ),
        );

    final repo = CachedCustomersRepository(
      db: db,
      remote: SupabaseCustomersRepository(null),
    );
    final recent = await repo.listRecent(limit: 2);
    expect(recent.map((c) => c.id).toList(), ['c-new', 'c-mid']);
  });
}
