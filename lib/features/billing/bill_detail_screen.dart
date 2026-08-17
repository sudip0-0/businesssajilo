import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bill_status_chip.dart';
import '../../core/ui/error_state.dart';
import '../../core/utils/bill_customer_label.dart';
import '../../core/utils/bs_date.dart';
import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../core/utils/role_label.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../auth/providers/auth_provider.dart';
import '../customers/providers.dart';
import 'credit_note_form_screen.dart';
import 'credit_note_providers.dart';
import 'invoice_export_actions.dart';
import 'bill_lines_table.dart';
import 'providers.dart';

class BillDetailScreen extends ConsumerStatefulWidget {
  const BillDetailScreen({
    super.key,
    required this.billId,
    this.embedded = false,
  });

  final String billId;
  final bool embedded;

  @override
  ConsumerState<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends ConsumerState<BillDetailScreen> {
  var _changed = false;

  String _formatBillCreator(AppLocalizations l10n, Bill bill) {
    final name = bill.createdByName?.trim();
    final roleRaw = bill.createdByRole?.trim();
    Role? role;
    if (roleRaw != null && roleRaw.isNotEmpty) {
      for (final value in Role.values) {
        if (value.name == roleRaw) {
          role = value;
          break;
        }
      }
    }
    final roleText = role == null ? null : roleLabel(l10n, role);
    if (name != null && name.isNotEmpty && roleText != null) {
      return '$name · $roleText';
    }
    return name?.isNotEmpty == true ? name! : (roleText ?? bill.createdBy);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final billId = widget.billId;
    final billAsync = ref.watch(billDetailProvider(billId));
    final role = ref.watch(authProvider).value?.member?.role;
    final canReturn = role?.canBill == true;

    final content = billAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(billDetailProvider(billId)),
      ),
      data: (bill) {
        final locale = Localizations.localeOf(context);
        final dateStr = bill.createdAt != null
            ? BsDate.both(bill.createdAt!, locale: locale)
            : '—';
        final timeStr = bill.createdAt != null
            ? BsDate.time(bill.createdAt!, locale: locale)
            : '—';
        final creator =
            (bill.createdByName != null || bill.createdByRole != null)
            ? _formatBillCreator(l10n, bill)
            : null;
        final receivedAsync = bill.status == BillStatus.partial
            ? ref.watch(billReceivedTotalProvider(bill.id))
            : null;
        final amountReceived = receivedAsync?.value;

        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _BillActions(
                bill: bill,
                canReturn: canReturn,
                embedded: widget.embedded,
                onChanged: () => setState(() => _changed = true),
              ),
              const SizedBox(height: 12),
              _BillSummaryCard(
                l10n: l10n,
                bill: bill,
                dateStr: dateStr,
                timeStr: timeStr,
                creator: creator,
              ),
              const SizedBox(height: 12),
              _BillLinesCard(
                l10n: l10n,
                bill: bill,
                amountReceived: amountReceived,
              ),
            ],
          ),
        );
      },
    );

    if (widget.embedded) return content;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.billDetail)),
        body: content,
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(BsRadii.xl),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BillActions extends ConsumerWidget {
  const _BillActions({
    required this.bill,
    required this.canReturn,
    required this.embedded,
    required this.onChanged,
  });

  final Bill bill;
  final bool canReturn;
  final bool embedded;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final returnedAsync = canReturn && bill.customerId != null
        ? ref.watch(billReturnedQtyProvider(bill.id))
        : null;
    final showReturn =
        returnedAsync?.maybeWhen(
          data: (returned) => bill.items.any((item) {
            final already = returned[item.id] ?? 0;
            return item.qty - already > 0;
          }),
          orElse: () => false,
        ) ??
        false;
    const actionStyle = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
      minimumSize: WidgetStatePropertyAll(Size(0, 48)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton(
            onPressed: () => exportBillAsPng(ref, context, bill),
            style: actionStyle,
            child: _ActionButtonLabel(
              icon: Icons.chat_outlined,
              label: l10n.shareViaWhatsApp,
            ),
          ),
        ),
        if (showReturn) ...[
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: _ReturnItemsButton(
              bill: bill,
              embedded: embedded,
              onChanged: onChanged,
              style: actionStyle,
            ),
          ),
        ],
        const SizedBox(width: 6),
        Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsRadii.lg),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: SizedBox(
            width: 48,
            height: 48,
            child: PopupMenuButton<String>(
              tooltip: l10n.export,
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_horiz, color: scheme.onSurface),
              onSelected: (value) {
                switch (value) {
                  case 'print':
                    exportBillPrint(ref, context, bill);
                  case 'copyImage':
                    exportBillCopyImage(ref, context, bill);
                  case 'pdf':
                    exportBillPdfDownload(ref, context, bill);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'print', child: Text(l10n.printInvoice)),
                PopupMenuItem(
                  value: 'copyImage',
                  child: Text(l10n.copyBillAsImage),
                ),
                PopupMenuItem(value: 'pdf', child: Text(l10n.downloadPdf)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  const _BillSummaryCard({
    required this.l10n,
    required this.bill,
    required this.dateStr,
    required this.timeStr,
    required this.creator,
  });

  final AppLocalizations l10n;
  final Bill bill;
  final String dateStr;
  final String timeStr;
  final String? creator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return _BillCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          bill.billNo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (bill.pendingSync) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: l10n.provisionalBillNo,
                          child: Icon(
                            Icons.schedule,
                            color: scheme.accentColor,
                            size: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                BillStatusChip(bill.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              billCustomerLabel(bill, walkInLabel: l10n.walkIn),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            if (bill.customerId != null)
              _CustomerContactLine(customerId: bill.customerId!),
            if (creator != null) ...[
              const SizedBox(height: 2),
              Text('${l10n.billCreatedBy}: $creator', style: muted),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _InlineMeta(icon: Icons.calendar_today_outlined, text: dateStr),
                _InlineMeta(icon: Icons.schedule_outlined, text: timeStr),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(text, style: style),
      ],
    );
  }
}

class _BillLinesCard extends StatelessWidget {
  const _BillLinesCard({
    required this.l10n,
    required this.bill,
    this.amountReceived,
  });

  final AppLocalizations l10n;
  final Bill bill;
  final int? amountReceived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final received = amountReceived;
    final lineDiscounts = lineDiscountsTotalPaisa(
      bill.items.map((item) => item.discount),
    );
    final itemsGross = bill.itemsTotal + lineDiscounts;
    return _BillCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.table_rows_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.billLines,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(BsRadii.lg),
              child: bill.items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        l10n.noBillLines,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : BillLinesTable(
                      l10n: l10n,
                      lines: [
                        for (final item in bill.items)
                          BillLineView(
                            name: item.nameSnapshot,
                            qty: '${item.qty}',
                            rate: formatNpr(Paisa(item.rate), showPaisa: false),
                            amount: formatNpr(
                              Paisa(
                                lineGrossPaisa(
                                  qty: item.qty,
                                  ratePaisa: item.rate,
                                ),
                              ),
                              showPaisa: false,
                            ),
                            discount: item.discount > 0
                                ? formatNpr(
                                    Paisa(item.discount),
                                    showPaisa: false,
                                  )
                                : null,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TotalRow(
                    label: l10n.total,
                    value: formatNpr(Paisa(itemsGross), showPaisa: false),
                  ),
                  if (lineDiscounts > 0) ...[
                    const SizedBox(height: 8),
                    _TotalRow(
                      label: l10n.discount,
                      value: formatNpr(Paisa(lineDiscounts), showPaisa: false),
                    ),
                  ],
                  if (bill.discount > 0) ...[
                    const SizedBox(height: 8),
                    _TotalRow(
                      label: l10n.billDiscount,
                      value:
                          '-${formatNpr(Paisa(bill.discount), showPaisa: false)}',
                    ),
                  ],
                  const SizedBox(height: 10),
                  _TotalRow(
                    label: l10n.grandTotal,
                    value: formatNpr(Paisa(bill.grandTotal), showPaisa: false),
                  ),
                  if (received != null) ...[
                    const SizedBox(height: 8),
                    _TotalRow(
                      label: l10n.amountPaid,
                      value: formatNpr(Paisa(received), showPaisa: false),
                    ),
                    const SizedBox(height: 8),
                    _TotalRow(
                      label: l10n.remainingDue,
                      value: formatNpr(
                        Paisa(
                          remainingDuePaisa(
                            grandTotal: bill.grandTotal,
                            amountReceived: received,
                          ),
                        ),
                        showPaisa: false,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CustomerContactLine extends ConsumerWidget {
  const _CustomerContactLine({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    return customerAsync.maybeWhen(
      data: (customer) {
        final phone = customer.phone?.trim();
        final contact = customer.contactName?.trim();
        final address = customer.address?.trim();
        if ((phone == null || phone.isEmpty) &&
            (contact == null || contact.isEmpty) &&
            (address == null || address.isEmpty)) {
          return const SizedBox.shrink();
        }
        final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (phone != null && phone.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(child: Text(phone, style: muted)),
                  ],
                )
              else if (contact != null && contact.isNotEmpty)
                Text(contact, style: muted),
              if (address != null && address.isNotEmpty) ...[
                if ((phone != null && phone.isNotEmpty) ||
                    (contact != null && contact.isNotEmpty))
                  const SizedBox(height: 4),
                Text(address, style: muted),
              ],
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ActionButtonLabel extends StatelessWidget {
  const _ActionButtonLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, maxLines: 1, softWrap: false),
        ],
      ),
    );
  }
}

class _ReturnItemsButton extends ConsumerWidget {
  const _ReturnItemsButton({
    required this.bill,
    this.embedded = false,
    this.onChanged,
    this.style,
  });

  final Bill bill;
  final bool embedded;
  final VoidCallback? onChanged;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final returnedAsync = ref.watch(billReturnedQtyProvider(bill.id));

    return returnedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (returned) {
        final hasReturnable = bill.items.any((item) {
          final already = returned[item.id] ?? 0;
          return item.qty - already > 0;
        });
        if (!hasReturnable) return const SizedBox.shrink();

        return OutlinedButton(
          onPressed: () async {
            if (embedded) {
              final segments = GoRouterState.of(context).uri.pathSegments;
              if (segments.length >= 2) {
                final changed = await context.push<bool>(
                  '/${segments[0]}/${segments[1]}/${bill.id}/return',
                );
                if (changed == true) {
                  ref.invalidate(billDetailProvider(bill.id));
                  ref.invalidate(billReturnedQtyProvider(bill.id));
                  onChanged?.call();
                }
              }
              return;
            }
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => CreditNoteFormScreen(bill: bill),
              ),
            );
            if (changed == true && context.mounted) {
              ref.invalidate(billDetailProvider(bill.id));
              ref.invalidate(billReturnedQtyProvider(bill.id));
              onChanged?.call();
            }
          },
          style: (style ?? const ButtonStyle()).merge(
            OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: _ActionButtonLabel(
            icon: Icons.keyboard_return_rounded,
            label: l10n.returnItems,
          ),
        );
      },
    );
  }
}
