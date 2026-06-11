import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import 'dues_aging_screen.dart';
import 'sales_summary_screen.dart';
import 'stock_valuation_screen.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (
        icon: Icons.trending_up,
        title: l10n.salesSummary,
        screen: const SalesSummaryScreen(),
      ),
      (
        icon: Icons.hourglass_bottom,
        title: l10n.duesAging,
        screen: const DuesAgingScreen(),
      ),
      (
        icon: Icons.inventory,
        title: l10n.stockValuation,
        screen: const StockValuationScreen(),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: Icon(item.icon, color: BsColors.primary),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item.screen),
            ),
          ),
        );
      },
    );
  }
}
