import '../l10n/app_localizations.dart';
import '../../data/sync/sync_helpers.dart';

String syncEntityLabel(AppLocalizations l10n, String entityType) =>
    switch (entityType) {
      'bill' => l10n.syncEntityBill,
      'payment' => l10n.syncEntityPayment,
      'stock_movement' => l10n.syncEntityStockMovement,
      'customer' => l10n.syncEntityCustomer,
      'product' => l10n.syncEntityProduct,
      _ => entityType,
    };

String syncErrorDetail(AppLocalizations l10n, String? raw) {
  final extracted = extractSyncErrorDetail(raw);
  if (extracted == null) return l10n.syncErrorGeneric;
  final lower = extracted.toLowerCase();
  if (lower.contains('customer not found')) {
    return l10n.syncErrorCustomerNotFound;
  }
  if (lower.contains('ambiguous customer')) {
    return l10n.syncErrorAmbiguousCustomer;
  }
  if (lower.contains('product does not belong')) {
    return l10n.syncErrorStaleProduct;
  }
  return extracted;
}

String syncStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'pending' => l10n.syncStatusPending,
      'failed' => l10n.syncStatusFailed,
      'synced' => l10n.syncStatusSynced,
      _ => status,
    };
