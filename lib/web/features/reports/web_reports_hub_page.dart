import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../layout/web_bento_grid.dart';
import '../web_page_scaffold.dart';

class WebReportsHubPage extends StatelessWidget {
  const WebReportsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WebPageScaffold(
      title: l10n.reports,
      body: WebBentoGrid(
        columns: 2,
        children: [
          WebBentoTile(
            onTap: () => context.go('/owner/reports/sales'),
            child: _ReportTile(
              icon: PhosphorIconsRegular.chartLineUp,
              title: l10n.salesSummary,
            ),
          ),
          WebBentoTile(
            onTap: () => context.go('/owner/reports/dues'),
            child: _ReportTile(
              icon: PhosphorIconsRegular.wallet,
              title: l10n.duesAging,
            ),
          ),
          WebBentoTile(
            onTap: () => context.go('/owner/reports/stock'),
            child: _ReportTile(
              icon: PhosphorIconsRegular.package,
              title: l10n.stockValuation,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28),
        const Spacer(),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
