import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/ledger_row.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/utils/ledger_balance.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/customers_repository.dart';
import '../../domain/models/ledger_entry.dart';
import '../billing/customer_bill_list_screen.dart';
import 'providers.dart';

class CustomerLedgerScreen extends ConsumerStatefulWidget {
  const CustomerLedgerScreen({super.key, this.showBillHistory = false});

  final bool showBillHistory;

  @override
  ConsumerState<CustomerLedgerScreen> createState() =>
      _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends ConsumerState<CustomerLedgerScreen> {
  int _tab = 0;
  PaginatedListState<LedgerEntry>? _pager;
  String? _pagerCustomerId;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initPager(String customerId) {
    if (_pagerCustomerId == customerId) return;
    _pagerCustomerId = customerId;
    _pager = PaginatedListState<LedgerEntry>(
      loadPage: (offset, limit) => ref
          .read(customersRepositoryProvider)
          .ledger(customerId, offset: offset, limit: limit),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customerAsync = ref.watch(ownCustomerProvider);

    return customerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(ownCustomerProvider),
      ),
      data: (customer) {
        if (customer == null) {
          return EmptyState(
            icon: Icons.storefront_outlined,
            message: l10n.noCustomers,
          );
        }
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _initPager(customer.id));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.myDues,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      formatNpr(Paisa(customer.balanceDue), showPaisa: false),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: customer.balanceDue > 0
                                ? BsColors.danger
                                : BsColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.showBillHistory)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 0, label: Text(l10n.ledger)),
                    ButtonSegment(value: 1, label: Text(l10n.billHistory)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
            if (widget.showBillHistory && _tab == 1)
              const Expanded(child: CustomerBillListScreen())
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.ledger,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildLedgerList(l10n),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLedgerList(AppLocalizations l10n) {
    final pager = _pager;
    if (pager == null || pager.initialLoading) {
      return const ListSkeleton();
    }
    if (pager.error != null && pager.items.isEmpty) {
      return ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => pager.refresh(),
      );
    }
    if (pager.items.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: l10n.noLedgerEntries,
      );
    }
    // Pages arrive in ascending order, so the running balance over the
    // accumulated prefix is correct.
    final entries = withRunningBalance(pager.items);
    return ListView.builder(
      controller: _scrollController,
      itemCount: entries.length + (pager.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= entries.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: pager.loading
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: pager.loadMore,
                      child: Text(l10n.loadMore),
                    ),
            ),
          );
        }
        final entry = entries[index];
        final description = switch (entry.entryType) {
          'opening_balance' => l10n.entryOpeningBalance,
          'bill' => '${l10n.entryBill} · ${entry.description}',
          'payment' =>
            '${l10n.entryPayment}${entry.description.isNotEmpty ? ' · ${entry.description}' : ''}',
          _ => entry.description,
        };
        return LedgerRow(
          date: entry.occurredAt,
          description: description,
          debit: Paisa(entry.debitPaisa),
          credit: Paisa(entry.creditPaisa),
          runningBalance: Paisa(entry.runningBalance),
        );
      },
    );
  }
}
