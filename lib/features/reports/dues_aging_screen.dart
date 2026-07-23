import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'report_export_actions.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/money.dart';
import '../../domain/models/aging_customer_row.dart';
import 'providers.dart';

class DuesAgingScreen extends ConsumerStatefulWidget {
  const DuesAgingScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<DuesAgingScreen> createState() => _DuesAgingScreenState();
}

class _DuesAgingScreenState extends ConsumerState<DuesAgingScreen> {
  // Sort field + direction live in state; build only derives a sorted copy.
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reportAsync = ref.watch(duesAgingProvider);

    final body = reportAsync.when(
      loading: () => const ListSkeleton(),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(duesAgingProvider),
      ),
      data: (report) {
        final sorted = _sortedCustomers(report.customers);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.embedded)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l10n.exportCsv,
                  onPressed: () => exportDuesAgingCsv(ref, context, report),
                  icon: const Icon(Icons.download_outlined),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _BucketCard(
                    label: l10n.aging0to30,
                    amount: report.bucket0to30,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BucketCard(
                    label: l10n.aging31to60,
                    amount: report.bucket31to60,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BucketCard(
                    label: l10n.aging60plus,
                    amount: report.bucket60plus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (report.customers.isEmpty)
              EmptyState(icon: Icons.hourglass_bottom, message: l10n.noDues)
            else if (isWideLayout(context))
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  columns: [
                    DataColumn(
                      label: Text(l10n.customers),
                      onSort: (_, asc) => _onSort(0, asc),
                    ),
                    DataColumn(
                      label: Text(l10n.dues),
                      numeric: true,
                      onSort: (_, asc) => _onSort(1, asc),
                    ),
                    DataColumn(
                      label: Text(l10n.ageDays),
                      numeric: true,
                      onSort: (_, asc) => _onSort(2, asc),
                    ),
                  ],
                  rows: sorted
                      .map(
                        (c) => DataRow(
                          cells: [
                            DataCell(Text(c.shopName)),
                            DataCell(
                              Text(
                                formatNpr(
                                  Paisa(c.balanceDue),
                                  showPaisa: false,
                                ),
                              ),
                            ),
                            DataCell(Text('${c.ageDays}')),
                          ],
                        ),
                      )
                      .toList(),
                ),
              )
            else
              ...sorted.map(
                (c) => ListTile(
                  title: Text(c.shopName),
                  subtitle: Text('${c.ageDays} ${l10n.ageDays}'),
                  trailing: MoneyText(Paisa(c.balanceDue), showPaisa: false),
                ),
              ),
          ],
        );
      },
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.duesAging),
        actions: [
          IconButton(
            tooltip: l10n.exportCsv,
            onPressed: reportAsync.hasValue
                ? () =>
                      exportDuesAgingCsv(ref, context, reportAsync.requireValue)
                : null,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: body,
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<AgingCustomerRow> _sortedCustomers(List<AgingCustomerRow> customers) {
    final sorted = List<AgingCustomerRow>.from(customers);
    if (_sortColumnIndex == null) return sorted;
    sorted.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => a.shopName.compareTo(b.shopName),
        1 => a.balanceDue.compareTo(b.balanceDue),
        2 => a.ageDays.compareTo(b.ageDays),
        _ => 0,
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }
}

class _BucketCard extends StatelessWidget {
  const _BucketCard({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            MoneyText(Paisa(amount), showPaisa: false),
          ],
        ),
      ),
    );
  }
}
