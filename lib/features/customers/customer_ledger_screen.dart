import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/ledger_row.dart';
import '../../core/utils/money.dart';
import 'providers.dart';

class CustomerLedgerScreen extends ConsumerWidget {
  const CustomerLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customerAsync = ref.watch(ownCustomerProvider);
    final ledgerAsync = ref.watch(ownLedgerProvider);

    return customerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (customer) {
        if (customer == null) {
          return EmptyState(
            icon: Icons.storefront_outlined,
            message: l10n.noCustomers,
          );
        }

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
                    Text(l10n.myDues, style: Theme.of(context).textTheme.titleMedium),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.ledger, style: Theme.of(context).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            Expanded(
              child: ledgerAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (entries) {
                  if (entries.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: l10n.noLedgerEntries,
                    );
                  }
                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final description = entry.entryType == 'opening_balance'
                          ? l10n.entryOpeningBalance
                          : entry.description;
                      return LedgerRow(
                        date: entry.occurredAt,
                        description: description,
                        debit: Paisa(entry.debitPaisa),
                        credit: Paisa(entry.creditPaisa),
                        runningBalance: Paisa(entry.runningBalance),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
