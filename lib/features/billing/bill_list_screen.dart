import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bill_status_chip.dart';
import '../../core/ui/empty_state.dart';
import '../../core/utils/money.dart';
import '../../domain/models/bill.dart';
import 'bill_detail_screen.dart';
import 'bill_form_screen.dart';
import 'providers.dart';

class BillListScreen extends ConsumerStatefulWidget {
  const BillListScreen({super.key});

  @override
  ConsumerState<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends ConsumerState<BillListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final billsAsync = ref.watch(billListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.filterBills,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: billsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (bills) {
              final filtered = bills.where((b) {
                if (_query.isEmpty) return true;
                return b.billNo.toLowerCase().contains(_query) ||
                    (b.customerShopName?.toLowerCase().contains(_query) ??
                        false);
              }).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: l10n.noBills,
                  actionLabel: l10n.newBill,
                  onAction: () => _openForm(context),
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final bill = filtered[index];
                  return _BillTile(
                    bill: bill,
                    onTap: () => _openDetail(context, bill),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BillFormScreen()),
    );
    if (saved == true) {
      ref.invalidate(billListProvider);
      ref.invalidate(todaysSalesProvider);
      ref.invalidate(todaysBillCountProvider);
    }
  }

  Future<void> _openDetail(BuildContext context, Bill bill) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillDetailScreen(billId: bill.id),
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({required this.bill, required this.onTap});

  final Bill bill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customerLabel =
        bill.customerShopName ?? l10n.walkIn;

    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.receipt_long_outlined, color: BsColors.primary),
      title: Text(bill.billNo),
      subtitle: Text(customerLabel),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatNpr(Paisa(bill.grandTotal), showPaisa: false),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          BillStatusChip(bill.status),
        ],
      ),
    );
  }
}
