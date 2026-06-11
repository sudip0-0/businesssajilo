import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/ledger_row.dart';
import '../../core/utils/money.dart';
import 'customer_form_screen.dart';
import 'providers.dart';
import 'record_payment_sheet.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    this.canEdit = false,
    this.canRecordPayments = false,
  });

  final String customerId;
  final bool canEdit;
  final bool canRecordPayments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ledgerAsync = ref.watch(customerLedgerProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: customerAsync.when(
          data: (c) => Text(c.shopName),
          loading: () => Text(l10n.customers),
          error: (_, _) => Text(l10n.customers),
        ),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerFormScreen(customerId: customerId),
                  ),
                );
                if (saved == true) {
                  ref.invalidate(customerDetailProvider(customerId));
                  ref.invalidate(customerLedgerProvider(customerId));
                  ref.invalidate(customerListProvider);
                  ref.invalidate(totalDuesProvider);
                }
              },
            ),
        ],
      ),
      floatingActionButton: canRecordPayments
          ? FloatingActionButton.extended(
              onPressed: () async {
                final customer = customerAsync.value;
                if (customer == null) return;
                final saved = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => RecordPaymentSheet(
                    customerId: customerId,
                    customerName: customer.shopName,
                  ),
                );
                if (saved == true) {
                  ref.invalidate(customerDetailProvider(customerId));
                  ref.invalidate(customerLedgerProvider(customerId));
                  ref.invalidate(customerListProvider);
                  ref.invalidate(totalDuesProvider);
                  if (context.mounted) Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.payments_outlined),
              label: Text(l10n.recordPayment),
            )
          : null,
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (customer) {
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
                      Text(l10n.currentBalance, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        formatNpr(Paisa(customer.balanceDue), showPaisa: false),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: customer.balanceDue > 0
                                  ? BsColors.danger
                                  : BsColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (customer.contactName != null) ...[
                        const SizedBox(height: 8),
                        Text(customer.contactName!),
                      ],
                      if (customer.phone != null) Text(customer.phone!),
                      if (customer.address != null) Text(customer.address!),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.ledger,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.ledgerDebit, style: Theme.of(context).textTheme.labelSmall)),
                    Expanded(child: Text(l10n.ledgerCredit, style: Theme.of(context).textTheme.labelSmall)),
                    SizedBox(
                      width: 96,
                      child: Text(
                        l10n.runningBalance,
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
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
                            : entry.entryType == 'payment'
                                ? '${l10n.entryPayment}${entry.description.isNotEmpty ? ' · ${entry.description}' : ''}'
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
      ),
    );
  }
}
