import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/money.dart';
import '../customers/customer_detail_screen.dart';
import 'providers.dart';
import 'report_export_actions.dart';

enum _DuesSortOption { highestDue, lowestDue, nameAZ }

class DuesAgingScreen extends ConsumerStatefulWidget {
  const DuesAgingScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<DuesAgingScreen> createState() => _DuesAgingScreenState();
}

class _DuesAgingScreenState extends ConsumerState<DuesAgingScreen> {
  _DuesSortOption _sortOption = _DuesSortOption.highestDue;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        final totalDues = report.customers.fold<int>(
          0,
          (sum, c) => sum + c.balanceDue,
        );
        final customerCount = report.customers.length;
        final avgDue = customerCount > 0 ? (totalDues ~/ customerCount) : 0;
        final maxDue = report.customers.fold<int>(
          0,
          (max, c) => c.balanceDue > max ? c.balanceDue : max,
        );

        final filtered = report.customers.where((c) {
          if (_search.isEmpty) return true;
          final q = _search.toLowerCase();
          return c.shopName.toLowerCase().contains(q) ||
              (c.phone != null && c.phone!.contains(q));
        }).toList();

        filtered.sort((a, b) {
          return switch (_sortOption) {
            _DuesSortOption.highestDue => b.balanceDue.compareTo(a.balanceDue),
            _DuesSortOption.lowestDue => a.balanceDue.compareTo(b.balanceDue),
            _DuesSortOption.nameAZ => a.shopName.toLowerCase().compareTo(
              b.shopName.toLowerCase(),
            ),
          };
        });

        final isWide = isWideLayout(context);

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
            // Summary Cards Bento
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isWide ? 2.0 : 1.35,
              children: [
                _StatCard(
                  label: l10n.totalDues,
                  value: formatNpr(Paisa(totalDues), showPaisa: false),
                  icon: Icons.account_balance_wallet_outlined,
                  color: BsColors.danger,
                ),
                _StatCard(
                  label: l10n.customersWithDues,
                  value: '$customerCount',
                  icon: Icons.people_outline,
                  color: BsColors.primary,
                ),
                _StatCard(
                  label: l10n.averageDue,
                  value: formatNpr(Paisa(avgDue), showPaisa: false),
                  icon: Icons.calculate_outlined,
                  color: Colors.deepPurple,
                ),
                _StatCard(
                  label: l10n.highestDue,
                  value: formatNpr(Paisa(maxDue), showPaisa: false),
                  icon: Icons.priority_high,
                  color: Colors.amber.shade800,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Search and sort bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: l10n.searchCustomersHint,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _search = val.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_DuesSortOption>(
                  tooltip: l10n.sortBy,
                  icon: const Icon(Icons.sort),
                  initialValue: _sortOption,
                  onSelected: (opt) => setState(() => _sortOption = opt),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _DuesSortOption.highestDue,
                      child: Text(l10n.sortHighestDue),
                    ),
                    PopupMenuItem(
                      value: _DuesSortOption.lowestDue,
                      child: Text(l10n.sortLowestDue),
                    ),
                    PopupMenuItem(
                      value: _DuesSortOption.nameAZ,
                      child: Text(l10n.sortNameAZ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.customerDuesList,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: EmptyState(
                  icon: Icons.check_circle_outline,
                  message: l10n.noDues,
                ),
              )
            else ...[
              for (final c in filtered) ...[
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: BsColors.danger.withValues(alpha: 0.12),
                      child: Text(
                        c.shopName.isNotEmpty
                            ? c.shopName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: BsColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      c.shopName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: c.phone != null && c.phone!.isNotEmpty
                        ? Text(c.phone!)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            MoneyText(
                              Paisa(c.balanceDue),
                              showPaisa: false,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: BsColors.danger,
                              ),
                            ),
                            Text(
                              l10n.due,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: BsColors.outline),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: BsColors.outline,
                          size: 20,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerDetailScreen(customerId: c.customerId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
