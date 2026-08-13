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
        final dateStr = bill.createdAt != null
            ? BsDate.both(
                bill.createdAt!,
                locale: Localizations.localeOf(context),
              )
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _BillActions(
                bill: bill,
                canReturn: canReturn,
                embedded: widget.embedded,
                onChanged: () => setState(() => _changed = true),
              ),
              const SizedBox(height: 16),
              _BillSummaryCard(
                l10n: l10n,
                bill: bill,
                dateStr: dateStr,
                creator: creator,
                amountReceived: amountReceived,
              ),
              const SizedBox(height: 16),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: () => exportBillAsPng(ref, context, bill),
          icon: const Icon(Icons.chat_outlined, size: 18),
          label: Text(l10n.shareViaWhatsApp),
        ),
        if (canReturn && bill.customerId != null)
          _ReturnItemsButton(
            bill: bill,
            embedded: embedded,
            onChanged: onChanged,
          ),
        Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsRadii.lg),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: PopupMenuButton<String>(
            tooltip: l10n.export,
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_horiz, color: scheme.onSurface),
            onSelected: (value) {
              switch (value) {
                case 'print':
                  exportBillPrint(ref, context, bill);
                case 'pdf':
                  exportBillPdfDownload(ref, context, bill);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'print', child: Text(l10n.printInvoice)),
              PopupMenuItem(value: 'pdf', child: Text(l10n.downloadPdf)),
            ],
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
    required this.creator,
    this.amountReceived,
  });

  final AppLocalizations l10n;
  final Bill bill;
  final String dateStr;
  final String? creator;
  final int? amountReceived;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconWash = scheme.primary.withValues(alpha: 0.08);
    final iconColor = scheme.primary;

    return _BillCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            final left = _SummaryLeft(
              l10n: l10n,
              bill: bill,
              creator: creator,
              iconWash: iconWash,
              iconColor: iconColor,
            );
            final right = _SummaryRight(
              l10n: l10n,
              bill: bill,
              dateStr: dateStr,
              iconWash: iconWash,
              iconColor: iconColor,
              alignEnd: wide,
              amountReceived: amountReceived,
            );

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  left,
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  right,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: left),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: scheme.outlineVariant,
                  ),
                  Expanded(flex: 2, child: right),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryLeft extends StatelessWidget {
  const _SummaryLeft({
    required this.l10n,
    required this.bill,
    required this.creator,
    required this.iconWash,
    required this.iconColor,
  });

  final AppLocalizations l10n;
  final Bill bill;
  final String? creator;
  final Color iconWash;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _IconBadge(
              icon: Icons.description_outlined,
              wash: iconWash,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      bill.billNo,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (bill.pendingSync) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: l10n.provisionalBillNo,
                      child: Icon(
                        Icons.schedule,
                        color: scheme.accentColor,
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.customerName,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          billCustomerLabel(bill, walkInLabel: l10n.walkIn),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        if (bill.customerId != null)
          _CustomerContactLine(customerId: bill.customerId!),
        if (creator != null) ...[
          const SizedBox(height: 16),
          Text(
            l10n.billCreatedBy,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            creator!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryRight extends StatelessWidget {
  const _SummaryRight({
    required this.l10n,
    required this.bill,
    required this.dateStr,
    required this.iconWash,
    required this.iconColor,
    required this.alignEnd,
    this.amountReceived,
  });

  final AppLocalizations l10n;
  final Bill bill;
  final String dateStr;
  final Color iconWash;
  final Color iconColor;
  final bool alignEnd;
  final int? amountReceived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final received = amountReceived;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        BillStatusChip(bill.status),
        if (received != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.amountPaid,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatNpr(Paisa(received), showPaisa: false),
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.remainingDue,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatNpr(
              Paisa(
                remainingDuePaisa(
                  grandTotal: bill.grandTotal,
                  amountReceived: received,
                ),
              ),
              showPaisa: false,
            ),
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(
              icon: Icons.calendar_today_outlined,
              wash: iconWash,
              color: iconColor,
              size: 32,
              iconSize: 16,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.billDate,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          dateStr,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.wash,
    required this.color,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color wash;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
      child: Icon(icon, size: iconSize, color: color),
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
              child: Column(
                children: [
                  ColoredBox(
                    color: scheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: _BillLinesHeader(l10n: l10n),
                    ),
                  ),
                  if (bill.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        l10n.noBillLines,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < bill.items.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, color: scheme.outlineVariant),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: _BillLineRow(
                          name: bill.items[i].nameSnapshot,
                          qty: '${bill.items[i].qty}',
                          rate: formatNpr(
                            Paisa(bill.items[i].rate),
                            showPaisa: false,
                          ),
                          amount: formatNpr(
                            Paisa(bill.items[i].lineTotal),
                            showPaisa: false,
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TotalRow(
                      label: l10n.total,
                      value: formatNpr(
                        Paisa(bill.itemsTotal),
                        showPaisa: false,
                      ),
                    ),
                    if (bill.discount > 0) ...[
                      const SizedBox(height: 8),
                      _TotalRow(
                        label: l10n.billDiscount,
                        value:
                            '-${formatNpr(Paisa(bill.discount), showPaisa: false)}',
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          l10n.grandTotal,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.successColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(BsRadii.full),
                          ),
                          child: Text(
                            formatNpr(Paisa(bill.grandTotal), showPaisa: false),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.successColor,
                            ),
                          ),
                        ),
                      ],
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
        if ((phone == null || phone.isEmpty) &&
            (contact == null || contact.isEmpty)) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              if (phone != null && phone.isNotEmpty) ...[
                Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ] else if (contact != null && contact.isNotEmpty)
                Flexible(
                  child: Text(
                    contact,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _BillLinesHeader extends StatelessWidget {
  const _BillLinesHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            l10n.productName,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(l10n.qty, style: style, textAlign: TextAlign.center),
        ),
        SizedBox(
          width: 96,
          child: Text(l10n.rate, style: style, textAlign: TextAlign.end),
        ),
        SizedBox(
          width: 104,
          child: Text(l10n.amountRs, style: style, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _BillLineRow extends StatelessWidget {
  const _BillLineRow({
    required this.name,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  final String name;
  final String qty;
  final String rate;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            name,
            style: body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(qty, style: body, textAlign: TextAlign.center),
        ),
        SizedBox(
          width: 96,
          child: Text(rate, style: body, textAlign: TextAlign.end),
        ),
        SizedBox(
          width: 104,
          child: Text(
            amount,
            style: body?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _ReturnItemsButton extends ConsumerWidget {
  const _ReturnItemsButton({
    required this.bill,
    this.embedded = false,
    this.onChanged,
  });

  final Bill bill;
  final bool embedded;
  final VoidCallback? onChanged;

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

        return OutlinedButton.icon(
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
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.keyboard_return_rounded, size: 18),
          label: Text(l10n.returnItems),
        );
      },
    );
  }
}
