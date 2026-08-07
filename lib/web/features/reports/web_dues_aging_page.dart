import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../features/reports/report_export_actions.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/report_range.dart';
import '../../../domain/models/aging_customer_row.dart';
import '../../../domain/models/dues_aging_report.dart';
import '../../../features/reports/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import '../../theme/web_typography.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_stat_tile.dart';
import '../web_page_scaffold.dart';
import 'widgets/aging_distribution_bar.dart';
import 'widgets/report_filter_bar.dart';

class WebDuesAgingPage extends ConsumerStatefulWidget {
  const WebDuesAgingPage({super.key, this.initialBucket});

  /// Optional deep-link bucket filter: `0_30` / `31_60` / `60_plus`.
  final String? initialBucket;

  @override
  ConsumerState<WebDuesAgingPage> createState() => _WebDuesAgingPageState();
}

class _WebDuesAgingPageState extends ConsumerState<WebDuesAgingPage> {
  int? _sortColumnIndex;
  bool _sortAscending = false;
  String? _bucketFilter;
  String _search = '';
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bucket = widget.initialBucket;
    if (bucket == '0_30' || bucket == '31_60' || bucket == '60_plus') {
      _bucketFilter = bucket;
    }
  }

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
          bucketFilter: _bucketFilter,
          search: _search,
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onBucketSelected: (bucket) => setState(() => _bucketFilter = bucket),
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
    required this.bucketFilter,
    required this.search,
    required this.searchController,
    required this.onSearchChanged,
    required this.onBucketSelected,
    required this.onSort,
  });

  final DuesAgingReport report;
  final int? sortColumnIndex;
  final bool sortAscending;
  final String? bucketFilter;
  final String search;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onBucketSelected;
  final void Function(int column, bool ascending) onSort;

  List<AgingCustomerRow> get _filtered {
    var rows = report.customers.where((c) {
      if (bucketFilter != null && c.bucket != bucketFilter) return false;
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
        0 => a.shopName.compareTo(b.shopName),
        1 => (a.phone ?? '').compareTo(b.phone ?? ''),
        2 => a.balanceDue.compareTo(b.balanceDue),
        3 => a.oldestDueAt.compareTo(b.oldestDueAt),
        4 => a.ageDays.compareTo(b.ageDays),
        5 => a.bucket.compareTo(b.bucket),
        _ => 0,
      };
      return sortAscending ? cmp : -cmp;
    });
    return rows;
  }

  int get _totalDues =>
      report.bucket0to30 + report.bucket31to60 + report.bucket60plus;

  int get _avgAgeDays {
    if (report.customers.isEmpty || _totalDues <= 0) return 0;
    final weighted = report.customers.fold<int>(
      0,
      (s, c) => s + c.ageDays * c.balanceDue,
    );
    return weighted ~/ _totalDues;
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
                      label: l10n.agingOver60,
                      value: formatNpr(
                        Paisa(report.bucket60plus),
                        showPaisa: false,
                      ),
                      icon: PhosphorIconsRegular.warning,
                      subtitle: l10n.aging60plus,
                    ),
                    WebStatTile(
                      label: l10n.avgAgeDays,
                      value: '$_avgAgeDays',
                      icon: PhosphorIconsRegular.clockCountdown,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                WebBentoTile(
                  minHeight: 88,
                  child: AgingDistributionBar(
                    bucket0to30: report.bucket0to30,
                    bucket31to60: report.bucket31to60,
                    bucket60plus: report.bucket60plus,
                    selectedBucket: bucketFilter,
                    onBucketSelected: onBucketSelected,
                  ),
                ),
                const SizedBox(height: 16),
                ReportFilterBar(
                  searchHint: l10n.searchCustomersHint,
                  searchController: searchController,
                  onSearchChanged: onSearchChanged,
                  filters: [
                    ChoiceChip(
                      label: Text(l10n.allBuckets),
                      selected: bucketFilter == null,
                      onSelected: (_) => onBucketSelected(null),
                    ),
                    ChoiceChip(
                      label: Text(l10n.aging0to30),
                      selected: bucketFilter == '0_30',
                      onSelected: (_) => onBucketSelected(
                        bucketFilter == '0_30' ? null : '0_30',
                      ),
                    ),
                    ChoiceChip(
                      label: Text(l10n.aging31to60),
                      selected: bucketFilter == '31_60',
                      onSelected: (_) => onBucketSelected(
                        bucketFilter == '31_60' ? null : '31_60',
                      ),
                    ),
                    ChoiceChip(
                      label: Text(l10n.aging60plus),
                      selected: bucketFilter == '60_plus',
                      onSelected: (_) => onBucketSelected(
                        bucketFilter == '60_plus' ? null : '60_plus',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (sorted.isEmpty)
                  WebEmptyState(
                    icon: PhosphorIconsRegular.hourglass,
                    message: report.customers.isEmpty
                        ? l10n.noDues
                        : l10n.noMatchingResults,
                  )
                else
                  SizedBox(
                    height: 420,
                    child: WebDataTable<AgingCustomerRow>(
                      columns: [
                        DataColumn(
                          label: Text(l10n.customers),
                          onSort: onSort,
                        ),
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
                        DataColumn(
                          label: Text(l10n.ageDays),
                          numeric: true,
                          onSort: onSort,
                        ),
                        DataColumn(label: Text(l10n.status), onSort: onSort),
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
                          DataCell(Text(c.shopName)),
                          DataCell(
                            Text(
                              c.phone?.isNotEmpty == true ? c.phone! : '—',
                              style: WebTypography.mono(fontSize: 12.5),
                            ),
                          ),
                          DataCell(
                            Text(
                              formatNpr(
                                Paisa(c.balanceDue),
                                showPaisa: false,
                              ),
                              style: WebTypography.mono(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: WebPalette.danger,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              dateFmt.format(
                                c.oldestDueAt.toUtc().add(nptOffset),
                              ),
                            ),
                          ),
                          DataCell(Text('${c.ageDays}')),
                          DataCell(_BucketChip(bucket: c.bucket)),
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

class _BucketChip extends StatelessWidget {
  const _BucketChip({required this.bucket});

  final String bucket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (bucket) {
      '0_30' => (l10n.aging0to30, WebPalette.success),
      '31_60' => (l10n.aging31to60, WebPalette.warning),
      _ => (l10n.aging60plus, WebPalette.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
