import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bill_status_chip.dart';
import '../../core/ui/error_state.dart';
import '../../core/utils/bs_date.dart';
import '../../core/utils/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../auth/providers/auth_provider.dart';
import 'credit_note_form_screen.dart';
import 'credit_note_providers.dart';
import 'invoice_export_actions.dart';
import 'providers.dart';

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({
    super.key,
    required this.billId,
    this.embedded = false,
  });

  final String billId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => exportBillAsPng(ref, context, bill),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(l10n.shareViaWhatsApp),
                ),
                if (canReturn && bill.customerId != null)
                  _ReturnItemsButton(bill: bill, embedded: embedded),
                PopupMenuButton<String>(
                  tooltip: l10n.export,
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    switch (value) {
                      case 'print':
                        exportBillPrint(ref, context, bill);
                      case 'pdf':
                        exportBillPdfDownload(ref, context, bill);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'print',
                      child: Text(l10n.printInvoice),
                    ),
                    PopupMenuItem(
                      value: 'pdf',
                      child: Text(l10n.downloadPdf),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    bill.billNo,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (bill.pendingSync)
                  Tooltip(
                    message: l10n.provisionalBillNo,
                    child: const Icon(
                      Icons.schedule,
                      color: BsColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(bill.customerShopName ?? l10n.walkIn),
            Text(dateStr),
            const SizedBox(height: 8),
            BillStatusChip(bill.status),
            const SizedBox(height: 16),
            Text(l10n.billLines, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...bill.items.map(
              (item) => ListTile(
                title: Text(item.nameSnapshot),
                subtitle: Text(
                  '${l10n.quantity}: ${item.qty} · ${l10n.rate}: ${formatNpr(Paisa(item.rate), showPaisa: false)}',
                ),
                trailing: Text(
                  formatNpr(Paisa(item.lineTotal), showPaisa: false),
                ),
              ),
            ),
            const Divider(),
            _SummaryRow(
              label: l10n.total,
              value: formatNpr(Paisa(bill.itemsTotal), showPaisa: false),
            ),
            if (bill.discount > 0)
              _SummaryRow(
                label: l10n.billDiscount,
                value:
                    '-${formatNpr(Paisa(bill.discount), showPaisa: false)}',
              ),
            _SummaryRow(
              label: l10n.grandTotal,
              value: formatNpr(Paisa(bill.grandTotal), showPaisa: false),
              bold: true,
            ),
          ],
        );
      },
    );

    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.billDetail)),
      body: content,
    );
  }
}

class _ReturnItemsButton extends ConsumerWidget {
  const _ReturnItemsButton({
    required this.bill,
    this.embedded = false,
  });

  final Bill bill;
  final bool embedded;

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
                context.push(
                  '/${segments[0]}/${segments[1]}/${bill.id}/return',
                );
              }
              return;
            }
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreditNoteFormScreen(bill: bill),
              ),
            );
          },
          icon: const Icon(Icons.undo_outlined, size: 18),
          label: Text(l10n.returnItems),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
