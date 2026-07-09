import '../l10n/app_localizations.dart';

String syncEntityLabel(AppLocalizations l10n, String entityType) =>
    switch (entityType) {
      'bill' => l10n.syncEntityBill,
      'payment' => l10n.syncEntityPayment,
      'stock_movement' => l10n.syncEntityStockMovement,
      'customer' => l10n.syncEntityCustomer,
      'product' => l10n.syncEntityProduct,
      _ => entityType,
    };

String syncStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'pending' => l10n.syncStatusPending,
      'failed' => l10n.syncStatusFailed,
      'synced' => l10n.syncStatusSynced,
      _ => status,
    };
