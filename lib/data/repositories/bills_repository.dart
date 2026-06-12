import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../remote/supabase_bills_repository.dart';
import '../remote/supabase_provider.dart';
import '../sync/sync_providers.dart';
import '../sync/syncing_bills_repository.dart';
import 'payments_repository.dart';

final billsRepositoryProvider = Provider<BillsRepository>((ref) {
  final syncBundle = ref.watch(syncBundleProvider);
  if (syncBundle != null) {
    return SyncingBillsRepository(
      db: syncBundle.db,
      sync: syncBundle.sync,
      payments: ref.watch(paymentsRepositoryProvider),
      businessId: syncBundle.businessId,
    );
  }
  return SupabaseBillsRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(paymentsRepositoryProvider),
  );
});

abstract class BillsRepository {
  Future<List<Bill>> list({int offset = 0, int? limit});
  Future<List<Bill>> search(String query, {int limit = 50});
  Future<Bill> get(String id);
  Future<int> todaysSales();
  Future<int> yesterdaysSales();
  Future<int> todaysBillCount();
  Future<List<Bill>> listTodaysBills({int limit = 20});
  Future<Bill> create({
    required String createdByMemberId,
    String? customerId,
    required BillStatus status,
    required int itemsTotal,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    PaymentMethod paymentMethod,
    String? paymentRefNote,
    int? paymentAmount,
  });
  Future<Bill> createFromOrder({
    required String orderId,
    required String customerId,
    required String createdByMemberId,
    required BillStatus status,
    required int itemsTotal,
    required int discount,
    required int grandTotal,
    required List<BillLineInput> lines,
    PaymentMethod paymentMethod,
    String? paymentRefNote,
    int? paymentAmount,
  });
}

class BillLineInput {
  const BillLineInput({
    required this.productId,
    required this.nameSnapshot,
    required this.qty,
    required this.rate,
    this.discount = 0,
    required this.lineTotal,
  });

  final String productId;
  final String nameSnapshot;
  final int qty;
  final int rate;
  final int discount;
  final int lineTotal;
}
