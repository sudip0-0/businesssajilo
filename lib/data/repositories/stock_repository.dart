import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/stock_movement.dart';
import '../remote/supabase_provider.dart';
import '../remote/supabase_stock_repository.dart';
import '../sync/sync_providers.dart';
import '../sync/syncing_stock_repository.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final bundle = ref.watch(syncBundleProvider);
  if (bundle != null) {
    return SyncingStockRepository(
      db: bundle.db,
      sync: bundle.sync,
      businessId: bundle.businessId,
    );
  }
  return SupabaseStockRepository(ref.watch(supabaseClientProvider));
});

abstract class StockRepository {
  Future<List<StockMovement>> listMovements(String productId);
  Future<StockMovement> stockIn({
    required String productId,
    required int qty,
    required String createdByMemberId,
  });
  Future<StockMovement> adjust({
    required String productId,
    required int qtyDelta,
    required String reason,
    required String createdByMemberId,
  });
}
