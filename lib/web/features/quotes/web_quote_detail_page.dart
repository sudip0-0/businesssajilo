import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/quotes/quote_detail_screen.dart';
import '../web_page_scaffold.dart';

/// Web host for [QuoteDetailScreen].
class WebQuoteDetailPage extends StatelessWidget {
  const WebQuoteDetailPage({super.key, required this.quoteId});

  final String quoteId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WebPageScaffold(
      title: l10n.quoteDetail,
      body: QuoteDetailScreen(quoteId: quoteId, embedded: true),
    );
  }
}
