import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/reports/sales_summary_screen.dart';
import '../web_page_scaffold.dart';

class WebSalesSummaryPage extends ConsumerWidget {
  const WebSalesSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return WebPageScaffold(
      title: l10n.salesSummary,
      breadcrumbs: [l10n.reports, l10n.salesSummary],
      body: const SalesSummaryScreen(embedded: true),
    );
  }
}
