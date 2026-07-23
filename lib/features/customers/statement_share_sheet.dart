import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/ui/inline_form_action.dart';
import '../../core/invoicing/statement_document.dart';
import '../../core/invoicing/statement_export_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/customers_repository.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../auth/providers/auth_provider.dart';
import 'statement_image_preview.dart';

/// Opens the statement share sheet for [customer].
Future<void> showStatementShareSheet(
  BuildContext context, {
  required Customer customer,
}) {
  final l10n = AppLocalizations.of(context);
  return showAdaptiveSheet<void>(
    context: context,
    title: l10n.shareStatement,
    child: StatementShareSheet(customer: customer),
  );
}

enum _StatementRange { last30, last90, all }

/// Date-range picker + share-as-PDF/image actions for a ledger statement.
class StatementShareSheet extends ConsumerStatefulWidget {
  const StatementShareSheet({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<StatementShareSheet> createState() =>
      _StatementShareSheetState();
}

class _StatementShareSheetState extends ConsumerState<StatementShareSheet> {
  _StatementRange _range = _StatementRange.last30;
  bool _loading = false;
  String? _error;

  Future<void> _share({required bool asPdf}) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final sheetNav = Navigator.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);
    await runInlineFormAction(
      action: () async {
        final business = await ref.read(currentBusinessProvider.future);
        if (business == null) throw StateError('no business');

        final entries = await ref
            .read(customersRepositoryProvider)
            .ledger(widget.customer.id);

        final now = DateTime.now().toUtc();
        final from = switch (_range) {
          _StatementRange.last30 => now.subtract(const Duration(days: 30)),
          _StatementRange.last90 => now.subtract(const Duration(days: 90)),
          _StatementRange.all => null,
        };

        final doc = StatementDocument.fromLedger(
          business: business,
          customerLabel: widget.customer.shopName,
          entries: entries,
          from: from,
          to: now,
          locale: locale,
          labels: StatementLabels(
            title: l10n.statement,
            period: l10n.statementPeriod,
            customer: l10n.customers,
            date: l10n.statementDate,
            description: l10n.statementDescription,
            debit: l10n.ledgerDebit,
            credit: l10n.ledgerCredit,
            balance: l10n.runningBalance,
            openingBalance: l10n.entryOpeningBalance,
            closingBalance: l10n.closingBalance,
          ),
          describeEntry: (entry) => _describeEntry(entry, l10n),
        );

        final service = ref.read(statementExportServiceProvider);
        if (asPdf) {
          await service.sharePdf(doc);
          if (mounted) sheetNav.pop();
          return;
        }

        final png = await service.buildPngBytes(doc);
        final fileName = service.fileName(doc);
        if (!mounted) return;
        sheetNav.pop();
        await showStatementImagePreview(
          rootNav.context,
          pngBytes: png,
          fileName: fileName,
        );
      },
      onState: ({required loading, error}) => setState(() {
        _loading = loading;
        _error = error;
      }),
      mounted: () => mounted,
      l10n: l10n,
      mapError: (e, l) => AppFailure.from(e).message(l),
    );
  }

  String _describeEntry(LedgerEntry entry, AppLocalizations l10n) {
    return switch (entry.entryType) {
      'opening_balance' => l10n.entryOpeningBalance,
      'bill' => '${l10n.entryBill} · ${entry.description}',
      'payment' =>
        '${l10n.entryPayment}${entry.description.isNotEmpty ? ' · ${entry.description}' : ''}',
      'credit_note' => '${l10n.creditNote} · ${entry.description}',
      _ => entry.description,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.shareStatement,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.statementPeriod,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<_StatementRange>(
            segments: [
              ButtonSegment(
                value: _StatementRange.last30,
                label: Text(l10n.rangeLast30Days),
              ),
              ButtonSegment(
                value: _StatementRange.last90,
                label: Text(l10n.rangeLast90Days),
              ),
              ButtonSegment(
                value: _StatementRange.all,
                label: Text(l10n.rangeAllTime),
              ),
            ],
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.first),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: BsColors.danger)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : () => _share(asPdf: false),
            icon: const Icon(Icons.image_outlined),
            label: Text(l10n.shareAsImage),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : () => _share(asPdf: true),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(l10n.shareAsPdf),
          ),
          if (_loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
