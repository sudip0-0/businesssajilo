import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/invoicing/statement_document.dart';
import '../../core/invoicing/statement_export_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/ui/inline_form_action.dart';
import '../../data/repositories/customers_repository.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/ledger_entry.dart';
import '../auth/providers/auth_provider.dart';
import '../reports/report_period.dart';
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

enum _StatementRange { last30, last90, all, custom }

/// Date-range picker with copy-as-image, preview, and share-as-PDF actions.
class StatementShareSheet extends ConsumerStatefulWidget {
  const StatementShareSheet({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<StatementShareSheet> createState() =>
      _StatementShareSheetState();
}

class _StatementShareSheetState extends ConsumerState<StatementShareSheet> {
  _StatementRange _range = _StatementRange.last30;
  DateTimeRange? _customRange;
  bool _loading = false;
  String? _error;

  Future<StatementDocument> _buildDocument(
    AppLocalizations l10n,
    Locale locale,
  ) async {
    final business = await ref.read(currentBusinessProvider.future);
    if (business == null) throw StateError('no business');

    final entries = await ref
        .read(customersRepositoryProvider)
        .ledger(widget.customer.id);

    final now = DateTime.now().toUtc();
    final DateTime? from;
    final DateTime to;
    switch (_range) {
      case _StatementRange.last30:
        from = now.subtract(const Duration(days: 30));
        to = now;
      case _StatementRange.last90:
        from = now.subtract(const Duration(days: 90));
        to = now;
      case _StatementRange.all:
        from = null;
        to = now;
      case _StatementRange.custom:
        final range = _customRange;
        if (range == null) {
          from = now.subtract(const Duration(days: 30));
          to = now;
        } else {
          final period = ReportPeriod.custom(
            fromDate: range.start,
            toDate: range.end,
          );
          from = period.from;
          // Statement range is inclusive; ReportPeriod.to is exclusive.
          to = period.to.subtract(const Duration(microseconds: 1));
        }
    }

    return StatementDocument.fromLedger(
      business: business,
      customerLabel: widget.customer.shopName,
      entries: entries,
      from: from,
      to: to,
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
  }

  Future<void> _copyImage() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final sheetNav = Navigator.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final service = ref.read(statementExportServiceProvider);
    // Start clipboard write before any await so web still has a user gesture.
    final copy = service.copyPng(() => _buildDocument(l10n, locale));
    await runInlineFormAction(
      action: () async {
        await copy;
        if (mounted) sheetNav.pop();
        if (rootContext.mounted) {
          showBsSnackBar(rootContext, message: l10n.statementImageCopied);
        }
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

  Future<void> _preview() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final sheetNav = Navigator.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);
    await runInlineFormAction(
      action: () async {
        final doc = await _buildDocument(l10n, locale);
        final png = await ref
            .read(statementExportServiceProvider)
            .buildPngBytes(doc);
        if (!mounted) return;
        sheetNav.pop();
        await showStatementImagePreview(rootNav.context, pngBytes: png);
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

  Future<void> _sharePdf() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final sheetNav = Navigator.of(context);
    await runInlineFormAction(
      action: () async {
        final doc = await _buildDocument(l10n, locale);
        await ref.read(statementExportServiceProvider).sharePdf(doc);
        if (mounted) sheetNav.pop();
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

  Future<void> _pickCustom() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial =
        _customRange ??
        DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 10),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: initial.start.isBefore(DateTime(today.year - 10))
            ? DateTime(today.year - 10)
            : initial.start,
        end: initial.end.isAfter(today) ? today : initial.end,
      ),
      helpText: l10n.periodCustom,
      cancelText: l10n.cancel,
      saveText: l10n.save,
    );
    if (range == null || !mounted) return;
    setState(() {
      _range = _StatementRange.custom;
      _customRange = range;
    });
  }

  String _customChipLabel(AppLocalizations l10n) {
    final range = _customRange;
    if (_range != _StatementRange.custom || range == null) {
      return l10n.periodCustom;
    }
    final fmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return '${fmt.format(range.start)} – ${fmt.format(range.end)}';
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(l10n.rangeLast30Days),
                selected: _range == _StatementRange.last30,
                onSelected: (_) =>
                    setState(() => _range = _StatementRange.last30),
              ),
              FilterChip(
                label: Text(l10n.rangeLast90Days),
                selected: _range == _StatementRange.last90,
                onSelected: (_) =>
                    setState(() => _range = _StatementRange.last90),
              ),
              FilterChip(
                label: Text(l10n.rangeAllTime),
                selected: _range == _StatementRange.all,
                onSelected: (_) => setState(() => _range = _StatementRange.all),
              ),
              FilterChip(
                avatar: Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: _range == _StatementRange.custom
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                label: Text(_customChipLabel(l10n)),
                selected: _range == _StatementRange.custom,
                onSelected: (_) => _pickCustom(),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: BsColors.danger)),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _copyImage,
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.copyAsImage),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _preview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.previewStatement),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : _sharePdf,
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
