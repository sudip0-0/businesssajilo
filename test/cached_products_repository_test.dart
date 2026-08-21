import 'package:businesssajilo/data/local/app_database.dart';
import 'package:businesssajilo/data/remote/supabase_products_repository.dart';
import 'package:businesssajilo/data/sync/cached_products_repository.dart';
import 'package:businesssajilo/domain/models/product.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingRemote extends SupabaseProductsRepository {
  _RecordingRemote() : super(null);

  Product? lastCreated;
  Product? lastUpdated;

  @override
  Future<Product> create({
    required String name,
    String? nameNp,
    String? sku,
    required String unit,
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
  }) async {
    lastCreated = Product(
      id: 'prod-remote-1',
      businessId: 'biz',
      name: name,
      nameNp: nameNp,
      sku: sku,
      unit: unit,
      costPrice: costPrice,
      referencePrice: referencePrice,
      lowStockThreshold: lowStockThreshold,
      updatedAt: DateTime.utc(2026, 8, 21),
      createdAt: DateTime.utc(2026, 8, 21),
    );
    return lastCreated!;
  }

  @override
  Future<Product> update({
    required String id,
    required String name,
    String? nameNp,
    String? sku,
    required String unit,
    int costPrice = 0,
    int referencePrice = 0,
    int lowStockThreshold = 0,
    String? imageUrl,
  }) async {
    lastUpdated = Product(
      id: id,
      businessId: 'biz',
      name: name,
      unit: unit,
      costPrice: costPrice,
      referencePrice: referencePrice,
      imageUrl: imageUrl,
      lowStockThreshold: lowStockThreshold,
      updatedAt: DateTime.utc(2026, 8, 22),
    );
    return lastUpdated!;
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('create mirrors the remote product into the local cache', () async {
    final remote = _RecordingRemote();
    final repo = CachedProductsRepository(db: db, remote: remote);

    final saved = await repo.create(
      name: 'Cola',
      sku: 'BS-1',
      unit: 'piece',
      costPrice: 5000,
      referencePrice: 6000,
      lowStockThreshold: 5,
    );

    // The mobile list reads from Drift; the new product must be there.
    final local = await (db.select(
      db.localProducts,
    )..where((p) => p.id.equals(saved.id))).getSingle();
    expect(local.name, 'Cola');
    expect(local.sku, 'BS-1');
    expect(local.costPrice, 5000);
    expect(local.referencePrice, 6000);
    expect(local.lowStockThreshold, 5);
    expect(local.isActive, isTrue);

    final listed = await repo.list();
    expect(listed.map((p) => p.id), contains('prod-remote-1'));
  });

  test('update mirrors edited fields into the local cache', () async {
    final remote = _RecordingRemote();
    final repo = CachedProductsRepository(db: db, remote: remote);

    final saved = await repo.create(name: 'Cola', unit: 'piece');
    final updated = await repo.update(
      id: saved.id,
      name: 'Cola Zero',
      unit: 'piece',
      costPrice: 7000,
      referencePrice: 8000,
      lowStockThreshold: 3,
    );

    final local = await (db.select(
      db.localProducts,
    )..where((p) => p.id.equals(updated.id))).getSingle();
    expect(local.name, 'Cola Zero');
    expect(local.costPrice, 7000);
    expect(local.referencePrice, 8000);
    expect(local.lowStockThreshold, 3);
  });
}
