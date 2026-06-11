import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bill_status_chip.dart';
import '../../core/utils/money.dart';
import 'providers.dart';

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final billAsync = ref.watch(billDetailProvider(billId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.billDetail)),
      body: billAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bill) {
          final dateStr = bill.createdAt != null
              ? DateFormat.yMMMd().add_jm().format(bill.createdAt!.toLocal())
              : '—';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bill.billNo,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                  value: '-${formatNpr(Paisa(bill.discount), showPaisa: false)}',
                ),
              _SummaryRow(
                label: l10n.grandTotal,
                value: formatNpr(Paisa(bill.grandTotal), showPaisa: false),
                bold: true,
              ),
            ],
          );
        },
      ),
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
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
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
