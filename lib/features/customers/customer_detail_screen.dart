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
import '../../domain/models/customer.dart';
import '../billing/bill_navigation.dart';
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
  final saved = await showAdaptiveSheet<bool>(
    context: context,
    title: l10n.recordPayment,
    child: RecordPaymentSheet(
      customerId: customerId,
      customerName: customerName,
    ),
  );
  if (saved != true) return;
  bumpCustomersRevision(ref);
  ref.invalidate(customerDetailProvider(customerId));
  ref.invalidate(customerLedgerProvider(customerId));
  ref.invalidate(customerListProvider);
  ref.invalidate(totalDuesProvider);
}

Future<void> _openRecordSaleSheet(
  BuildContext context,
  WidgetRef ref, {
  required String customerId,
  required String customerName,
}) async {
  final l10n = AppLocalizations.of(context);
  final saved = await showAdaptiveSheet<bool>(
    context: context,
    title: l10n.recordSale,
    child: RecordSaleSheet(customerId: customerId, customerName: customerName),
  );
  if (saved != true) return;
  bumpCustomersRevision(ref);
  ref.invalidate(customerDetailProvider(customerId));
  ref.invalidate(customerLedgerProvider(customerId));
  ref.invalidate(customerListProvider);
  ref.invalidate(totalDuesProvider);
}

Future<void> _openEditCustomer(
  BuildContext context,
  WidgetRef ref, {
  required String customerId,
}) async {
  final saved = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => CustomerFormScreen(customerId: customerId),
    ),
  );
  if (saved != true) return;
  bumpCustomersRevision(ref);
  ref.invalidate(customerDetailProvider(customerId));
  ref.invalidate(customerLedgerProvider(customerId));
  ref.invalidate(customerListProvider);
  ref.invalidate(totalDuesProvider);
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
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
      ),
      data: (customer) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (embedded) ...[
              if (canEdit && customer.memberId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _PortalStatusChip(memberId: customer.memberId),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canEdit)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l10n.editCustomer),
                        onPressed: () => _openEditCustomer(
                          context,
                          ref,
                          customerId: customerId,
                        ),
                      ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.ios_share_outlined, size: 18),
                      label: Text(l10n.shareStatement),
                      onPressed: () =>
                          showStatementShareSheet(context, customer: customer),
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
                    if (canEdit && customer.memberId.isNotEmpty)
                      _EmbeddedPortalAction(
                        memberId: customer.memberId,
                        customerName: customer.shopName,
                      ),
                  ],
                ),
              ),
            ],
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
                    if (canRecordPayments) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _openRecordSaleSheet(
                                context,
                                ref,
                                customerId: customerId,
                                customerName: customer.shopName,
                              ),
                              child: Text(
                                l10n.recordSale,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => _openRecordPaymentSheet(
                                context,
                                ref,
                                customerId: customerId,
                                customerName: customer.shopName,
                              ),
                              child: Text(
                                l10n.recordPayment,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
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
                skipLoadingOnReload: true,
                skipLoadingOnRefresh: true,
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
                    padding: const EdgeInsets.only(bottom: BsSpacing.xxl),
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
                      final billId = entry.entryType == 'bill'
                          ? entry.refId
                          : null;
                      return LedgerRow(
                        date: entry.occurredAt,
                        description: description,
                        debit: Paisa(entry.debitPaisa),
                        credit: Paisa(entry.creditPaisa),
                        runningBalance: Paisa(entry.runningBalance),
                        onTap: billId == null
                            ? null
                            : () => _openBill(context, ref, billId),
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
          data: (c) =>
              Text(c.shopName, maxLines: 1, overflow: TextOverflow.ellipsis),
          loading: () => Text(l10n.customers),
          error: (_, _) => Text(l10n.customers),
        ),
        actions: [
          customerAsync.maybeWhen(
            data: (c) => canEdit && c.memberId.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Center(
                      child: _PortalStatusChip(memberId: c.memberId),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          _CustomerMoreMenu(
            customerId: customerId,
            canEdit: canEdit,
            customerAsync: customerAsync,
          ),
        ],
      ),
      body: body,
    );
  }

  Future<void> _openBill(
    BuildContext context,
    WidgetRef ref,
    String billId,
  ) async {
    final changed = await pushBillDetail(context, ref, billId);
    if (changed == true && context.mounted) {
      ref.invalidate(customerLedgerProvider(customerId));
      ref.invalidate(customerDetailProvider(customerId));
    }
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
          visualDensity: VisualDensity.compact,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          avatar: Icon(
            member.isActive ? Icons.login : Icons.lock_outline,
            size: 16,
          ),
          label: Text(
            member.isActive ? l10n.portalActive : l10n.portalDisabled,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        );
      },
    );
  }
}

class _EmbeddedPortalAction extends ConsumerWidget {
  const _EmbeddedPortalAction({
    required this.memberId,
    required this.customerName,
  });

  final String memberId;
  final String customerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final member = ref.watch(customerMemberProvider(memberId)).value;
    if (member == null) return const SizedBox.shrink();
    return TextButton(
      onPressed: () => _setPortalLogin(
        context,
        ref,
        memberId: memberId,
        customerName: customerName,
        enable: !member.isActive,
      ),
      child: Text(
        member.isActive ? l10n.disablePortalLogin : l10n.enablePortalLogin,
      ),
    );
  }
}

class _CustomerMoreMenu extends ConsumerWidget {
  const _CustomerMoreMenu({
    required this.customerId,
    required this.canEdit,
    required this.customerAsync,
  });

  final String customerId;
  final bool canEdit;
  final AsyncValue<Customer> customerAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customer = customerAsync.value;
    final memberId = customer?.memberId ?? '';
    final member = memberId.isEmpty
        ? null
        : ref.watch(customerMemberProvider(memberId)).value;

    return PopupMenuButton<_CustomerMoreAction>(
      tooltip: l10n.more,
      onSelected: (action) async {
        if (customer == null) return;
        switch (action) {
          case _CustomerMoreAction.share:
            await showStatementShareSheet(context, customer: customer);
          case _CustomerMoreAction.edit:
            await _openEditCustomer(context, ref, customerId: customerId);
          case _CustomerMoreAction.resetPassword:
            await showResetMemberPasswordSheet(
              context,
              memberId: customer.memberId,
              memberName: customer.shopName,
            );
          case _CustomerMoreAction.disablePortal:
            await _setPortalLogin(
              context,
              ref,
              memberId: customer.memberId,
              customerName: customer.shopName,
              enable: false,
            );
          case _CustomerMoreAction.enablePortal:
            await _setPortalLogin(
              context,
              ref,
              memberId: customer.memberId,
              customerName: customer.shopName,
              enable: true,
            );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CustomerMoreAction.share,
          child: Text(l10n.shareStatement),
        ),
        if (canEdit)
          PopupMenuItem(
            value: _CustomerMoreAction.edit,
            child: Text(l10n.editCustomer),
          ),
        if (canEdit)
          PopupMenuItem(
            value: _CustomerMoreAction.resetPassword,
            child: Text(l10n.resetPassword),
          ),
        if (canEdit && member != null)
          PopupMenuItem(
            value: member.isActive
                ? _CustomerMoreAction.disablePortal
                : _CustomerMoreAction.enablePortal,
            child: Text(
              member.isActive
                  ? l10n.disablePortalLogin
                  : l10n.enablePortalLogin,
            ),
          ),
      ],
    );
  }
}

enum _CustomerMoreAction {
  share,
  edit,
  resetPassword,
  disablePortal,
  enablePortal,
}

Future<void> _setPortalLogin(
  BuildContext context,
  WidgetRef ref, {
  required String memberId,
  required String customerName,
  required bool enable,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(enable ? l10n.enablePortalLogin : l10n.disablePortalLogin),
      content: Text(
        enable ? l10n.enablePortalConfirm : l10n.disablePortalConfirm,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            enable ? l10n.enablePortalLogin : l10n.disablePortalLogin,
          ),
        ),
      ],
    ),
  );
  if (confirm != true) return;
  final repo = ref.read(membersRepositoryProvider);
  if (enable) {
    await repo.activateMember(memberId);
  } else {
    await repo.deactivateMember(memberId);
  }
  ref.invalidate(customerMemberProvider(memberId));
  if (!enable || !context.mounted) return;
  await showResetMemberPasswordSheet(
    context,
    memberId: memberId,
    memberName: customerName,
  );
}
