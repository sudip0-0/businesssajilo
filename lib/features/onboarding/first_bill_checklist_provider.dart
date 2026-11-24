import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/business.dart';
import '../auth/providers/auth_provider.dart';
import '../billing/providers.dart';
import '../customers/providers.dart';
import '../inventory/providers.dart';

/// Per-business persistence for dismissing the Owner first-bill checklist.
class FirstBillChecklistStore {
  const FirstBillChecklistStore();

  String _key(String businessId) =>
      'bs_first_bill_checklist_dismissed_v1::${businessId.trim()}';

  Future<bool> isDismissed(String businessId) async {
    if (businessId.trim().isEmpty) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key(businessId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> dismiss(String businessId) async {
    if (businessId.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(businessId), true);
    } catch (_) {}
  }

  Future<void> reset(String businessId) async {
    if (businessId.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(businessId));
    } catch (_) {}
  }
}

final firstBillChecklistStoreProvider = Provider<FirstBillChecklistStore>(
  (ref) => const FirstBillChecklistStore(),
);

class _ChecklistDismissRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final _checklistDismissRevisionProvider =
    NotifierProvider<_ChecklistDismissRevision, int>(
      _ChecklistDismissRevision.new,
    );

/// Evaluates whether a business profile has enough info for invoices.
bool isBusinessProfileReady(Business? business) {
  if (business == null) return false;
  if (business.name.trim().isEmpty) return false;
  final hasPhone = business.phone?.trim().isNotEmpty ?? false;
  final hasAddress = business.address?.trim().isNotEmpty ?? false;
  return hasPhone || hasAddress;
}

class FirstBillChecklistState {
  const FirstBillChecklistState({
    required this.businessId,
    required this.businessProfileReady,
    required this.hasProduct,
    required this.hasCustomer,
    required this.hasBill,
    required this.dismissed,
  });

  final String businessId;
  final bool businessProfileReady;
  final bool hasProduct;
  final bool hasCustomer;
  final bool hasBill;
  final bool dismissed;

  int get totalCount => 4;

  int get completedCount =>
      (businessProfileReady ? 1 : 0) +
      (hasProduct ? 1 : 0) +
      (hasCustomer ? 1 : 0) +
      (hasBill ? 1 : 0);

  bool get isAllComplete => completedCount == totalCount;

  bool get shouldShow => !dismissed && !isAllComplete;
}

/// Live completion status for the Owner onboarding checklist.
///
/// Returns `null` for non-owners, unauthenticated sessions, or when data
/// cannot be verified (so dashboards never show misleading incomplete states).
final firstBillChecklistProvider =
    FutureProvider.autoDispose<FirstBillChecklistState?>((ref) async {
      final member = ref.watch(authProvider.select((s) => s.value?.member));
      if (member == null || member.role != Role.owner) return null;
      final businessId = member.businessId;
      if (businessId.trim().isEmpty) return null;

      ref.watch(_checklistDismissRevisionProvider);
      ref.watch(inventoryRevisionProvider);
      ref.watch(customersRevisionProvider);
      ref.watch(billingRevisionProvider);

      final store = ref.watch(firstBillChecklistStoreProvider);
      final dismissed = await store.isDismissed(businessId);
      if (dismissed) {
        return FirstBillChecklistState(
          businessId: businessId,
          businessProfileReady: false,
          hasProduct: false,
          hasCustomer: false,
          hasBill: false,
          dismissed: true,
        );
      }

      try {
        final business = await ref.watch(currentBusinessProvider.future);
        final productsRepo = ref.watch(productsRepositoryProvider);
        final customersRepo = ref.watch(customersRepositoryProvider);
        final billsRepo = ref.watch(billsRepositoryProvider);

        final results = await Future.wait([
          productsRepo.list(activeOnly: true, limit: 1),
          customersRepo.list(limit: 1, includeBalances: false),
          billsRepo.list(limit: 1),
        ]);

        return FirstBillChecklistState(
          businessId: businessId,
          businessProfileReady: isBusinessProfileReady(business),
          hasProduct: results[0].isNotEmpty,
          hasCustomer: results[1].isNotEmpty,
          hasBill: results[2].isNotEmpty,
          dismissed: false,
        );
      } catch (_) {
        return null;
      }
    });

/// Persists dismissal for [businessId] and refreshes the checklist provider.
Future<void> dismissFirstBillChecklist(WidgetRef ref, String businessId) async {
  await ref.read(firstBillChecklistStoreProvider).dismiss(businessId);
  ref.read(_checklistDismissRevisionProvider.notifier).bump();
}
