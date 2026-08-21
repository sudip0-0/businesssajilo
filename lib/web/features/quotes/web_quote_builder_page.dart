import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/quotes/quote_builder_screen.dart';
import '../web_page_scaffold.dart';

/// Web host for [QuoteBuilderScreen] (owner/sales).
class WebQuoteBuilderPage extends StatelessWidget {
  const WebQuoteBuilderPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WebPageScaffold(
      title: l10n.sendQuote,
      breadcrumbs: [l10n.orders, orderId.substring(0, 8)],
      body: QuoteBuilderScreen(orderId: orderId, embedded: true),
    );
  }
}
