import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/orders/cart_action.dart';
import '../../../features/orders/catalog_screen.dart';
import '../web_page_scaffold.dart';

class WebCatalogPage extends ConsumerWidget {
  const WebCatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return WebPageScaffold(
      title: l10n.catalog,
      actions: const [CartAction()],
      body: const CatalogScreen(),
    );
  }
}
