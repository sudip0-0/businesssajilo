import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ui/error_state.dart';
import '../../../../domain/models/bill.dart';
import '../../../../domain/models/customer.dart';
import '../../../../domain/models/product.dart';
import '../../../../features/reports/dashboard/dashboard_activity_feed.dart';
import '../../../theme/web_palette.dart';

/// Recent bills / low-stock / new-customer feed for the owner dashboard.
class WebDashboardRecentActivity extends StatelessWidget {
  const WebDashboardRecentActivity({
    super.key,
    required this.bills,
    required this.lowStockAlerts,
    required this.recentCustomers,
    this.onRetry,
  });

  final AsyncValue<List<Bill>> bills;
  final AsyncValue<List<Product>> lowStockAlerts;
  final AsyncValue<List<Customer>> recentCustomers;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (dashboardActivityHasError(
      billsError: bills.hasError,
      lowStockError: lowStockAlerts.hasError,
      recentCustomersError: recentCustomers.hasError,
    )) {
      return ErrorState(message: l10n.loadingFailed, onRetry: onRetry);
    }

    if (bills.isLoading || lowStockAlerts.isLoading || recentCustomers.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = buildDashboardActivityFeed(
      l10n: l10n,
      bills: bills.value,
      lowStockAlerts: lowStockAlerts.value,
      recentCustomers: recentCustomers.value,
    );

    if (dashboardActivityIsEmpty(
      items: items,
      billsLoaded: bills.hasValue,
      lowStockLoaded: lowStockAlerts.hasValue,
      recentCustomersLoaded: recentCustomers.hasValue,
    )) {
      return Center(
        child: Text(
          l10n.noRecentActivity,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: WebPalette.inkSoft),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ActivityItem(
          icon: switch (item.kind) {
            DashboardActivityKind.bill => PhosphorIconsRegular.receipt,
            DashboardActivityKind.lowStock => PhosphorIconsRegular.warning,
            DashboardActivityKind.newCustomer => PhosphorIconsRegular.user,
          },
          color: switch (item.kind) {
            DashboardActivityKind.bill => WebPalette.navy,
            DashboardActivityKind.lowStock => WebPalette.danger,
            DashboardActivityKind.newCustomer => WebPalette.success,
          },
          text: item.text,
          onTap: switch (item.kind) {
            DashboardActivityKind.bill => item.entityId == null
                ? null
                : () => context.go('/owner/billing/${item.entityId}'),
            DashboardActivityKind.lowStock => item.entityId == null
                ? null
                : () => context.go('/owner/inventory/${item.entityId}'),
            DashboardActivityKind.newCustomer => item.entityId == null
                ? null
                : () => context.go('/owner/customers/${item.entityId}'),
          },
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
