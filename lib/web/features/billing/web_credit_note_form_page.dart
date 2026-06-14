import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/error_state.dart';
import '../../../features/billing/credit_note_form_screen.dart';
import '../../../features/billing/providers.dart';
import '../web_page_scaffold.dart';

String _billingListPath(BuildContext context, String billId) {
  final segments = GoRouterState.of(context).uri.pathSegments;
  if (segments.length >= 2) {
    return '/${segments[0]}/${segments[1]}/$billId';
  }
  return '/owner/billing/$billId';
}

class WebCreditNoteFormPage extends ConsumerWidget {
  const WebCreditNoteFormPage({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final billAsync = ref.watch(billDetailProvider(billId));

    return WebPageScaffold(
      title: l10n.returnItems,
      breadcrumbs: [l10n.billing, l10n.returnItems],
      body: billAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: l10n.loadingFailed,
          onRetry: () => ref.invalidate(billDetailProvider(billId)),
        ),
        data: (bill) => CreditNoteFormScreen(
          bill: bill,
          embedded: true,
          onSaved: () => context.go(_billingListPath(context, billId)),
        ),
      ),
    );
  }
}
