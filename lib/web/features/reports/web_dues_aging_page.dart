import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/export/export_actions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../domain/models/aging_customer_row.dart';
import '../../../domain/models/dues_aging_report.dart';
import '../../../features/reports/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';

class WebDuesAgingPage extends ConsumerStatefulWidget {
  const WebDuesAgingPage({super.key});

  @override
  ConsumerState<WebDuesAgingPage> createState() => _WebDuesAgingPageState();
}

class _WebDuesAgingPageState extends ConsumerState<WebDuesAgingPage> {
  int? _sortColumnIndex;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reportAsync = ref.watch(duesAgingProvider);

    return WebPageScaffold(
      title: l10n.duesAging,
      breadcrumbs: [l10n.reports, l10n.duesAging],
      actions: [
        reportAsync.maybeWhen(
          data: (report) => IconButton(
            tooltip: l10n.exportCsv,
            onPressed: () => exportDuesAgingCsv(ref, context, report),
            icon: const Icon(Icons.download_outlined),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WebEmptyState(
          icon: PhosphorIconsRegular.warningCircle,
          message: l10n.loadingFailed,
          actionLabel: l10n.tryAgain,
          onAction: () => ref.invalidate(duesAgingProvider),
        ),
        data: (report) => _DuesBody(
          report: report,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          onSort: (column, asc) {
            setState(() {
              _sortColumnIndex = column;
              _sortAscending = asc;
            });
          },
        ),
      ),
    );
  }
}

class _DuesBody extends StatelessWidget {
  const _DuesBody({
    required this.report,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  final DuesAgingReport report;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int column, bool ascending) onSort;

  List<AgingCustomerRow> get _sorted {
    final rows = List<AgingCustomerRow>.from(report.customers);
    if (sortColumnIndex == null) {
      rows.sort((a, b) => b.balanceDue.compareTo(a.balanceDue));
      return rows;
    }
    rows.sort((a, b) {
      final cmp = switch (sortColumnIndex) {
        0 => a.shopName.compareTo(b.shopName),
        1 => a.balanceDue.compareTo(b.balanceDue),
        2 => a.ageDays.compareTo(b.ageDays),
        _ => 0,
      };
      return sortAscending ? cmp : -cmp;
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = _sorted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WebBentoGrid(
          columns: 3,
          children: [
            WebStatTile(
              label: l10n.aging0to30,
              value: formatNpr(Paisa(report.bucket0to30), showPaisa: false),
              icon: PhosphorIconsRegular.clock,
            ),
            WebStatTile(
              label: l10n.aging31to60,
              value: formatNpr(Paisa(report.bucket31to60), showPaisa: false),
              icon: PhosphorIconsRegular.clockCountdown,
            ),
            WebStatTile(
              label: l10n.aging60plus,
              value: formatNpr(Paisa(report.bucket60plus), showPaisa: false),
              icon: PhosphorIconsRegular.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (sorted.isEmpty)
          Expanded(
            child: WebEmptyState(
              icon: PhosphorIconsRegular.hourglass,
              message: l10n.noDues,
            ),
          )
        else
          Expanded(
            child: WebDataTable<AgingCustomerRow>(
              columns: [
                DataColumn(label: Text(l10n.customers), onSort: onSort),
                DataColumn(
                  label: Text(l10n.dues),
                  numeric: true,
                  onSort: onSort,
                ),
                DataColumn(
                  label: Text(l10n.ageDays),
                  numeric: true,
                  onSort: onSort,
                ),
              ],
              items: sorted,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              onSort: onSort,
              idFor: (c) => c.customerId,
              rowBuilder: (c, _) => DataRow(
                cells: [
                  DataCell(Text(c.shopName)),
                  DataCell(
                    Text(
                      formatNpr(Paisa(c.balanceDue), showPaisa: false),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: WebPalette.danger,
                      ),
                    ),
                  ),
                  DataCell(Text('${c.ageDays}')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
