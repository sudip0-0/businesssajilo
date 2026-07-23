import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../domain/models/bill.dart';
import '../../../../domain/models/customer.dart';
import '../../../../domain/models/product.dart';
import '../../../theme/web_palette.dart';

/// Recent bills / low-stock / new-customer feed for the owner dashboard.
class WebDashboardRecentActivity extends StatelessWidget {
  const WebDashboardRecentActivity({
    super.key,
    required this.bills,
    required this.lowStockAlerts,
    required this.recentCustomers,
  });

  final AsyncValue<List<Bill>> bills;
  final AsyncValue<List<Product>> lowStockAlerts;
  final AsyncValue<List<Customer>> recentCustomers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_ActivityItem>[];

    bills.whenData((list) {
      for (final bill in list.take(3)) {
        items.add(
          _ActivityItem(
            icon: PhosphorIconsRegular.receipt,
            color: WebPalette.navy,
            text: l10n.newBillCreated(bill.billNo),
            onTap: () => context.go('/owner/billing/${bill.id}'),
          ),
        );
      }
    });

    lowStockAlerts.whenData((list) {
      for (final p in list) {
        items.add(
          _ActivityItem(
            icon: PhosphorIconsRegular.warning,
            color: WebPalette.danger,
            text: l10n.lowStockAlert(p.name),
            onTap: () => context.go('/owner/inventory/${p.id}'),
          ),
        );
      }
    });

    recentCustomers.whenData((list) {
      for (final c in list) {
        items.add(
          _ActivityItem(
            icon: PhosphorIconsRegular.user,
            color: WebPalette.success,
            text: l10n.newCustomerAdded(c.shopName),
            onTap: () => context.go('/owner/customers/${c.id}'),
          ),
        );
      }
    });

    if (items.isEmpty) {
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
      itemCount: items.length.clamp(0, 5),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => items[index],
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
