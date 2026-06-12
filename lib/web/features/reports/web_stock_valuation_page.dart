import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/reports/stock_valuation_screen.dart';
import '../web_page_scaffold.dart';

class WebStockValuationPage extends ConsumerWidget {
  const WebStockValuationPage({
    super.key,
    this.lowStockOnly = false,
  });

  final bool lowStockOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return WebPageScaffold(
      title: lowStockOnly ? l10n.lowStock : l10n.stockValuation,
      breadcrumbs: [
        l10n.reports,
        lowStockOnly ? l10n.lowStock : l10n.stockValuation,
      ],
      body: StockValuationScreen(
        lowStockOnly: lowStockOnly,
        embedded: true,
      ),
    );
  }
}
