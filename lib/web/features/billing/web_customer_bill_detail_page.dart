import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/billing/bill_detail_screen.dart';
import '../web_page_scaffold.dart';

/// Web deep-link host for a customer's own bill (RLS-scoped).
class WebCustomerBillDetailPage extends StatelessWidget {
  const WebCustomerBillDetailPage({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WebPageScaffold(
      title: l10n.billDetail,
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/customer/dues'),
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          label: Text(l10n.myDues),
        ),
      ],
      body: BillDetailScreen(billId: billId, embedded: true),
    );
  }
}
