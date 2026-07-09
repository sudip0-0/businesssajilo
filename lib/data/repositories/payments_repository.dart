import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums.dart';
import '../../domain/models/payment.dart';
import '../remote/supabase_payments_repository.dart';
import '../remote/supabase_provider.dart';
import '../sync/sync_providers.dart';
import '../sync/syncing_payments_repository.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  final bundle = ref.watch(syncBundleProvider);
  if (bundle != null) {
    return SyncingPaymentsRepository(
      db: bundle.db,
      sync: bundle.sync,
      businessId: bundle.businessId,
    );
  }
  return SupabasePaymentsRepository(ref.watch(supabaseClientProvider));
});

abstract class PaymentsRepository {
  Future<List<Payment>> listByCustomer(String customerId);
  /// When [enqueueRemote] is false (offline bill path), the payment is stored
  /// locally only — the bill sync payload carries it into `create_bill`.
  Future<Payment> record({
    String? id,
    required String customerId,
    required int amount,
    required PaymentMethod method,
    String? refNote,
    String? billId,
    required String receivedByMemberId,
    bool enqueueRemote = true,
  });
  Future<int> totalDues();
}
