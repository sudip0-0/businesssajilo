import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../domain/models/aging_customer_row.dart';
import '../../../domain/models/dues_aging_report.dart';
import '../../../features/reports/providers.dart';
import '../../../features/reports/report_export_actions.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import '../../theme/web_typography.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';
import 'widgets/report_filter_bar.dart';

class WebDuesAgingPage extends ConsumerStatefulWidget {
  const WebDuesAgingPage({super.key, this.initialBucket});

  final String? initialBucket;

  @override
  ConsumerState<WebDuesAgingPage> createState() => _WebDuesAgingPageState();
}

class _WebDuesAgingPageState extends ConsumerState<WebDuesAgingPage> {
  int? _sortColumnIndex = 2;
  bool _sortAscending = false;
  String _search = '';
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _search = value.trim().toLowerCase());
    });
  }

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
          search: _search,
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
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
    required this.search,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSort,
  });

  final DuesAgingReport report;
  final int? sortColumnIndex;
  final bool sortAscending;
  final String search;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final void Function(int column, bool ascending) onSort;

  List<AgingCustomerRow> get _filtered {
    var rows = report.customers.where((c) {
      if (search.isEmpty) return true;
      final hay = '${c.shopName} ${c.phone ?? ''}'.toLowerCase();
      return hay.contains(search);
    }).toList();

    if (sortColumnIndex == null) {
      rows.sort((a, b) => b.balanceDue.compareTo(a.balanceDue));
      return rows;
    }
    rows.sort((a, b) {
      final cmp = switch (sortColumnIndex) {
        0 => a.shopName.toLowerCase().compareTo(b.shopName.toLowerCase()),
        1 => (a.phone ?? '').compareTo(b.phone ?? ''),
        2 => a.balanceDue.compareTo(b.balanceDue),
        3 => a.oldestDueAt.compareTo(b.oldestDueAt),
        _ => 0,
      };
      return sortAscending ? cmp : -cmp;
    });
    return rows;
  }

  int get _totalDues =>
      report.customers.fold<int>(0, (s, c) => s + c.balanceDue);

  int get _avgDue {
    if (report.customers.isEmpty) return 0;
    return _totalDues ~/ report.customers.length;
  }

  int get _maxDue {
    return report.customers.fold<int>(
      0,
      (max, c) => c.balanceDue > max ? c.balanceDue : max,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = _filtered;
    final dateFmt = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WebBentoGrid(
                  columns: 4,
                  children: [
                    WebStatTile(
                      label: l10n.totalDues,
                      value: formatNpr(Paisa(_totalDues), showPaisa: false),
                      icon: PhosphorIconsRegular.wallet,
                    ),
                    WebStatTile(
                      label: l10n.customersWithDues,
                      value: '${report.customers.length}',
                      icon: PhosphorIconsRegular.users,
                    ),
                    WebStatTile(
                      label: l10n.averageDue,
                      value: formatNpr(Paisa(_avgDue), showPaisa: false),
                      icon: PhosphorIconsRegular.calculator,
                    ),
                    WebStatTile(
                      label: l10n.highestDue,
                      value: formatNpr(Paisa(_maxDue), showPaisa: false),
                      icon: PhosphorIconsRegular.trendUp,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ReportFilterBar(
                  searchHint: l10n.searchCustomersHint,
                  searchController: searchController,
                  onSearchChanged: onSearchChanged,
                  filters: const [],
                ),
                const SizedBox(height: 12),
                if (sorted.isEmpty)
                  WebEmptyState(
                    icon: PhosphorIconsRegular.checkCircle,
                    message: report.customers.isEmpty
                        ? l10n.noDues
                        : l10n.noMatchingResults,
                  )
                else
                  SizedBox(
                    height: 500,
                    child: WebDataTable<AgingCustomerRow>(
                      columns: [
                        DataColumn(label: Text(l10n.customers), onSort: onSort),
                        DataColumn(label: Text(l10n.phone), onSort: onSort),
                        DataColumn(
                          label: Text(l10n.dues),
                          numeric: true,
                          onSort: onSort,
                        ),
                        DataColumn(
                          label: Text(l10n.oldestDue),
                          onSort: onSort,
                        ),
                        const DataColumn(label: Text('')),
                      ],
                      items: sorted,
                      sortColumnIndex: sortColumnIndex,
                      sortAscending: sortAscending,
                      onSort: onSort,
                      idFor: (c) => c.customerId,
                      onRowTap: (c) =>
                          context.go('/owner/customers/${c.customerId}'),
                      rowBuilder: (c, _) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              c.shopName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text(c.phone ?? '—')),
                          DataCell(
                            Text(
                              formatNpr(
                                Paisa(c.balanceDue),
                                showPaisa: false,
                              ),
                              style: WebTypography.mono(
                                color: WebPalette.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(dateFmt.format(c.oldestDueAt.toLocal())),
                          ),
                          DataCell(
                            TextButton.icon(
                              icon: const Icon(
                                PhosphorIconsRegular.arrowSquareOut,
                                size: 16,
                              ),
                              label: Text(l10n.viewCustomerLedger),
                              onPressed: () => context.go(
                                '/owner/customers/${c.customerId}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
