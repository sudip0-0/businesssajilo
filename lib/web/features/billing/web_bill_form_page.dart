import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import 'web_bill_form_content.dart';
import '../web_page_scaffold.dart';
import '../../../core/testing/integration_keys.dart';

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

class WebBillFormPage extends ConsumerStatefulWidget {
  const WebBillFormPage({super.key});

  @override
  ConsumerState<WebBillFormPage> createState() => _WebBillFormPageState();
}

class _WebBillFormPageState extends ConsumerState<WebBillFormPage> {
  final _formKey = GlobalKey<WebBillFormContentState>();

  void _onSaved() {
    bumpBillingRevision(ref);
    ref.invalidate(billListProvider);
    ref.invalidate(todaysSalesProvider);
    ref.invalidate(todaysBillCountProvider);
    ref.invalidate(todaysBillsProvider);
    ref.invalidate(totalDuesProvider);
    context.go(_billingListPath(context));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final backPath = _billingListPath(context);

    return WebPageScaffold(
      title: l10n.createNewBill,
      subtitle: l10n.createBillSubtitle,
      breadcrumbs: [l10n.billing, l10n.createNewBill],
      actions: [
        OutlinedButton(
          key: IntegrationKeys.billFormCancel,
          onPressed: () => context.go(backPath),
          child: Text(l10n.cancel),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          key: IntegrationKeys.billFormSaveDraft,
          onPressed: () => _formKey.currentState?.saveDraft(),
          child: Text(l10n.saveAsDraft),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => _formKey.currentState?.saveBill(),
          icon: Icon(PhosphorIconsRegular.floppyDisk, size: 18),
          label: Text(l10n.saveBill),
        ),
      ],
      body: WebBillFormContent(key: _formKey, onSaved: _onSaved),
    );
  }
}
