import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/billing/bill_form_screen.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../web_page_scaffold.dart';

String _billingListPath(BuildContext context) {
  final path = GoRouterState.of(context).uri.path;
  if (path.endsWith('/new')) {
    return path.replaceFirst(RegExp(r'/new$'), '');
  }
  final segments = GoRouterState.of(context).uri.pathSegments;
  if (segments.length >= 2) {
    return '/${segments[0]}/${segments[1]}';
  }
  return path;
}

class WebBillFormPage extends ConsumerWidget {
  const WebBillFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final backPath = _billingListPath(context);

    return WebPageScaffold(
      title: l10n.newBill,
      breadcrumbs: [l10n.billing],
      actions: [
        TextButton(
          onPressed: () => context.go(backPath),
          child: Text(l10n.cancel),
        ),
      ],
      body: BillFormScreen(
        embedded: true,
        onSaved: () {
          ref.invalidate(billListProvider);
          ref.invalidate(todaysSalesProvider);
          ref.invalidate(todaysBillCountProvider);
          ref.invalidate(totalDuesProvider);
          context.go(backPath);
        },
      ),
    );
  }
}
