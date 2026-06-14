import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/export/export_share_service.dart';
import '../../core/export/report_csv_export.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/ledger_balance.dart';
import '../../core/utils/report_range.dart';
import '../../domain/enums.dart';
import '../../domain/models/dues_aging_report.dart';
import '../../domain/models/ledger_entry.dart';
import '../../domain/models/stock_valuation_row.dart';
import '../../data/repositories/customers_repository.dart';
import '../../features/billing/providers.dart';
import '../../features/reports/providers.dart';

Future<void> exportSalesReportCsv(
  WidgetRef ref,
  BuildContext context,
  ReportRange range,
) async {
  final l10n = AppLocalizations.of(context);
  final daily = await ref.read(salesDailyProvider(range).future);
  final topProducts = await ref.read(topProductsProvider(range).future);
  final topCustomers = await ref.read(topCustomersProvider(range).future);
  final filename =
      'businesssajilo-sales-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
  await ref.read(exportShareServiceProvider).shareCsv(
        filename: filename,
        subject: l10n.salesSummary,
        rows: salesReportCsvRows(
          daily: daily,
          topProducts: topProducts,
          topCustomers: topCustomers,
        ),
      );
}

Future<void> exportDuesAgingCsv(
  WidgetRef ref,
  BuildContext context,
  DuesAgingReport report,
) async {
  final l10n = AppLocalizations.of(context);
  final filename =
      'businesssajilo-dues-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
  await ref.read(exportShareServiceProvider).shareCsv(
        filename: filename,
        subject: l10n.duesAging,
        rows: duesAgingCsvRows(report),
      );
}

Future<void> exportStockValuationCsv(
  WidgetRef ref,
  BuildContext context,
  List<StockValuationRow> rows,
) async {
  final l10n = AppLocalizations.of(context);
  final filename =
      'businesssajilo-stock-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
  await ref.read(exportShareServiceProvider).shareCsv(
        filename: filename,
        subject: l10n.stockValuation,
        rows: stockValuationCsvRows(rows),
      );
}

Future<void> exportCustomerLedgerCsv(
  WidgetRef ref,
  BuildContext context,
  String customerId,
) async {
  final entries =
      await ref.read(customersRepositoryProvider).ledger(customerId);
  await exportLedgerCsv(ref, context, entries);
}

Future<void> exportLedgerCsv(
  WidgetRef ref,
  BuildContext context,
  List<LedgerEntry> entries,
) async {
  final l10n = AppLocalizations.of(context);
  final filename =
      'businesssajilo-ledger-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
  await ref.read(exportShareServiceProvider).shareCsv(
        filename: filename,
        subject: l10n.ledger,
        rows: ledgerCsvRows(withRunningBalance(entries)),
      );
}

Future<void> exportTodaysBillsCsv(
  WidgetRef ref,
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context);
  final bills = await ref.read(todaysBillsProvider.future);
  final filename =
      'businesssajilo-bills-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
  await ref.read(exportShareServiceProvider).shareCsv(
        filename: filename,
        subject: l10n.todaysTransactions,
        rows: todaysBillsCsvRows(bills),
      );
}
