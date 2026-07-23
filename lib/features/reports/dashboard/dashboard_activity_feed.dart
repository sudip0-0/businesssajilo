import '../../../core/l10n/app_localizations.dart';
import '../../../domain/models/bill.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/product.dart';

/// Pure activity feed item for owner dashboards (mobile + web).
class DashboardActivityItem {
  const DashboardActivityItem({
    required this.id,
    required this.text,
    required this.kind,
    this.entityId,
  });

  final String id;
  final String text;
  final DashboardActivityKind kind;
  final String? entityId;
}

enum DashboardActivityKind { bill, lowStock, newCustomer }

/// Builds a merged recent-activity feed from dashboard async sources.
List<DashboardActivityItem> buildDashboardActivityFeed({
  required AppLocalizations l10n,
  List<Bill>? bills,
  List<Product>? lowStockAlerts,
  List<Customer>? recentCustomers,
  int maxItems = 5,
}) {
  final items = <DashboardActivityItem>[];

  if (bills != null) {
    for (final bill in bills.take(3)) {
      items.add(
        DashboardActivityItem(
          id: 'bill-${bill.id}',
          text: l10n.newBillCreated(bill.billNo),
          kind: DashboardActivityKind.bill,
          entityId: bill.id,
        ),
      );
    }
  }

  if (lowStockAlerts != null) {
    for (final p in lowStockAlerts) {
      items.add(
        DashboardActivityItem(
          id: 'stock-${p.id}',
          text: l10n.lowStockAlert(p.name),
          kind: DashboardActivityKind.lowStock,
          entityId: p.id,
        ),
      );
    }
  }

  if (recentCustomers != null) {
    for (final c in recentCustomers) {
      items.add(
        DashboardActivityItem(
          id: 'customer-${c.id}',
          text: l10n.newCustomerAdded(c.shopName),
          kind: DashboardActivityKind.newCustomer,
          entityId: c.id,
        ),
      );
    }
  }

  return items.take(maxItems).toList();
}

/// True when any feed source failed to load.
bool dashboardActivityHasError({
  required bool billsError,
  required bool lowStockError,
  bool recentCustomersError = false,
}) {
  return billsError || lowStockError || recentCustomersError;
}

/// True when all loaded sources returned no activity items.
bool dashboardActivityIsEmpty({
  required List<DashboardActivityItem> items,
  required bool billsLoaded,
  required bool lowStockLoaded,
  bool recentCustomersLoaded = true,
}) {
  if (items.isNotEmpty) return false;
  return billsLoaded && lowStockLoaded && recentCustomersLoaded;
}
