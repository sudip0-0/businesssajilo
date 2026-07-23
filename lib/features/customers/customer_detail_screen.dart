import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/ledger_row.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/utils/money.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../data/repositories/members_repository.dart';
import '../staff/reset_member_password_sheet.dart';
import 'customer_form_screen.dart';
import 'providers.dart';
import 'record_payment_sheet.dart';
import 'record_sale_sheet.dart';
import 'statement_share_sheet.dart';

Future<void> _openRecordPaymentSheet(
  BuildContext context,
  WidgetRef ref, {
  required String customerId,
  required String customerName,
}) async {
  final l10n = AppLocalizations.of(context);
  await showAdaptiveSheet<bool>(
    context: context,
    title: l10n.recordPayment,
    child: RecordPaymentSheet(
      customerId: customerId,
      customerName: customerName,
    ),
  );
  // Cache invalidation is handled by recordCustomerPayment.
}

Future<void> _openRecordSaleSheet(
  BuildContext context,
  WidgetRef ref, {
  required String customerId,
  required String customerName,
}) async {
  final l10n = AppLocalizations.of(context);
  await showAdaptiveSheet<bool>(
    context: context,
    title: l10n.recordSale,
    child: RecordSaleSheet(customerId: customerId, customerName: customerName),
  );
  // Cache invalidation is handled by recordCustomerSale.
}

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    this.canEdit = false,
    this.canRecordPayments = false,
    this.embedded = false,
  });

  final String customerId;
  final bool canEdit;
  final bool canRecordPayments;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ledgerAsync = ref.watch(customerLedgerProvider(customerId));

    final body = customerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
      ),
      data: (customer) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Embedded (web master-detail) has no app bar; surface the
            // same actions inline.
            if (embedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canRecordPayments)
                      FilledButton.icon(
                        icon: const Icon(
                          Icons.point_of_sale_outlined,
                          size: 18,
                        ),
                        label: Text(l10n.recordSale),
                        onPressed: () => _openRecordSaleSheet(
                          context,
                          ref,
                          customerId: customerId,
                          customerName: customer.shopName,
                        ),
                      ),
                    if (canRecordPayments && customer.balanceDue > 0)
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: Text(l10n.recordPayment),
                        onPressed: () => _openRecordPaymentSheet(
                          context,
                          ref,
                          customerId: customerId,
                          customerName: customer.shopName,
                        ),
                      ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.ios_share_outlined, size: 18),
                      label: Text(l10n.shareStatement),
                      onPressed: () =>
                          showStatementShareSheet(context, customer: customer),
                    ),
                    if (canRecordPayments && customer.balanceDue <= 0)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: Text(l10n.recordPayment),
                        onPressed: () => _openRecordPaymentSheet(
                          context,
                          ref,
                          customerId: customerId,
                          customerName: customer.shopName,
                        ),
                      ),
                    if (canEdit)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.lock_reset_outlined, size: 18),
                        label: Text(l10n.resetPassword),
                        onPressed: () => showResetMemberPasswordSheet(
                          context,
                          memberId: customer.memberId,
                          memberName: customer.shopName,
                        ),
                      ),
                  ],
                ),
              ),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentBalance,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatNpr(Paisa(customer.balanceDue), showPaisa: false),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
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
                    if (canEdit && customer.memberId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _PortalStatusChip(memberId: customer.memberId),
                      const SizedBox(height: 8),
                      _PortalLoginButton(
                        memberId: customer.memberId,
                        customerName: customer.shopName,
                      ),
                    ],
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
            LedgerTableHeader(
              dateLabel: l10n.ledgerDate,
              descriptionLabel: l10n.ledgerDescription,
              debitLabel: l10n.ledgerDebit,
              creditLabel: l10n.ledgerCredit,
              balanceLabel: l10n.runningBalance,
            ),
            const Divider(height: 1),
            Expanded(
              child: ledgerAsync.when(
                loading: () => const ListSkeleton(),
                error: (e, _) => ErrorState(
                  message: l10n.loadingFailed,
                  onRetry: () =>
                      ref.invalidate(customerLedgerProvider(customerId)),
                ),
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
                },
              ),
            ),
          ],
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: customerAsync.when(
          data: (c) => Text(c.shopName),
          loading: () => Text(l10n.customers),
          error: (_, _) => Text(l10n.customers),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: l10n.shareStatement,
            onPressed: () {
              final customer = customerAsync.value;
              if (customer == null) return;
              showStatementShareSheet(context, customer: customer);
            },
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.lock_reset_outlined),
              tooltip: l10n.resetPassword,
              onPressed: () {
                final customer = customerAsync.value;
                if (customer == null) return;
                showResetMemberPasswordSheet(
                  context,
                  memberId: customer.memberId,
                  memberName: customer.shopName,
                );
              },
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editCustomer,
              onPressed: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerFormScreen(customerId: customerId),
                  ),
                );
                if (saved == true) {
                  bumpCustomersRevision(ref);
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
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'record_sale_$customerId',
                  onPressed: () async {
                    final customer = customerAsync.value;
                    if (customer == null) return;
                    await _openRecordSaleSheet(
                      context,
                      ref,
                      customerId: customerId,
                      customerName: customer.shopName,
                    );
                  },
                  icon: const Icon(Icons.point_of_sale_outlined),
                  label: Text(l10n.recordSale),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'record_payment_$customerId',
                  onPressed: () async {
                    final customer = customerAsync.value;
                    if (customer == null) return;
                    await _openRecordPaymentSheet(
                      context,
                      ref,
                      customerId: customerId,
                      customerName: customer.shopName,
                    );
                  },
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(l10n.recordPayment),
                ),
              ],
            )
          : null,
      body: body,
    );
  }
}

class _PortalStatusChip extends ConsumerWidget {
  const _PortalStatusChip({required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final memberAsync = ref.watch(customerMemberProvider(memberId));
    return memberAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (member) {
        if (member == null) return const SizedBox.shrink();
        return Chip(
          avatar: Icon(
            member.isActive ? Icons.login : Icons.lock_outline,
            size: 16,
          ),
          label: Text(
            member.isActive ? l10n.portalActive : l10n.portalDisabled,
          ),
        );
      },
    );
  }
}

class _PortalLoginButton extends ConsumerWidget {
  const _PortalLoginButton({
    required this.memberId,
    required this.customerName,
  });

  final String memberId;
  final String customerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final memberAsync = ref.watch(customerMemberProvider(memberId));
    return memberAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (member) {
        if (member == null) return const SizedBox.shrink();
        if (member.isActive) {
          return OutlinedButton.icon(
            icon: const Icon(Icons.person_off_outlined, size: 18),
            label: Text(l10n.disablePortalLogin),
            onPressed: () => _disable(context, ref),
          );
        }
        return OutlinedButton.icon(
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: Text(l10n.enablePortalLogin),
          onPressed: () => _enable(context, ref),
        );
      },
    );
  }

  Future<void> _disable(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.disablePortalLogin),
        content: Text(l10n.disablePortalConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.disablePortalLogin),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(membersRepositoryProvider).deactivateMember(memberId);
    ref.invalidate(customerMemberProvider(memberId));
  }

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enablePortalLogin),
        content: Text(l10n.enablePortalConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.enablePortalLogin),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(membersRepositoryProvider).activateMember(memberId);
    ref.invalidate(customerMemberProvider(memberId));
    if (!context.mounted) return;
    await showResetMemberPasswordSheet(
      context,
      memberId: memberId,
      memberName: customerName,
    );
  }
}
