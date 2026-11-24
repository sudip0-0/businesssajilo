import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/quotes/quote_builder_screen.dart';
import '../web_page_scaffold.dart';

/// Web host for [QuoteBuilderScreen] (owner/sales) with Ctrl/Cmd+S shortcut.
class WebQuoteBuilderPage extends StatefulWidget {
  const WebQuoteBuilderPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<WebQuoteBuilderPage> createState() => _WebQuoteBuilderPageState();
}

class _WebQuoteBuilderPageState extends State<WebQuoteBuilderPage> {
  final _builderKey = GlobalKey<QuoteBuilderScreenState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shortId = widget.orderId.length > 8
        ? widget.orderId.substring(0, 8)
        : widget.orderId;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          _builderKey.currentState?.sendQuote();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          _builderKey.currentState?.sendQuote();
        },
      },
      child: Focus(
        autofocus: true,
        child: WebPageScaffold(
          title: l10n.sendQuote,
          breadcrumbs: [l10n.orders, shortId],
          body: QuoteBuilderScreen(
            key: _builderKey,
            orderId: widget.orderId,
            embedded: true,
          ),
        ),
      ),
    );
  }
}
