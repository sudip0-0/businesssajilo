import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/orders/catalog_screen.dart';
import '../web_page_scaffold.dart';

class WebCatalogPage extends StatelessWidget {
  const WebCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WebPageScaffold(
      title: l10n.catalog,
      body: const CatalogScreen(),
    );
  }
}
