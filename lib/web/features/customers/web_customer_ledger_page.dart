import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/customers/customer_ledger_screen.dart';
import '../web_page_scaffold.dart';

class WebCustomerLedgerPage extends StatelessWidget {
  const WebCustomerLedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WebPageScaffold(
      title: l10n.myDues,
      body: const CustomerLedgerScreen(showBillHistory: true),
    );
  }
}
