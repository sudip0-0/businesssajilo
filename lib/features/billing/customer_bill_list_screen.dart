import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/bs_date.dart';
import '../../core/ui/bill_status_chip.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/utils/money.dart';
import 'bill_detail_screen.dart';
import 'providers.dart';

class CustomerBillListScreen extends ConsumerWidget {
  const CustomerBillListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final billsAsync = ref.watch(billListProvider);

    return billsAsync.when(
      loading: () => const ListSkeleton(),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(billListProvider),
      ),
      data: (bills) {
        if (bills.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            message: l10n.noBills,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(billListProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: bills.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final bill = bills[index];
              final dateStr = bill.createdAt != null
                  ? BsDate.both(
                      bill.createdAt!,
                      locale: Localizations.localeOf(context),
                    )
                  : '—';
              return ListTile(
                title: Text(bill.billNo),
                subtitle: Text(dateStr),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatNpr(Paisa(bill.grandTotal), showPaisa: false)),
                    BillStatusChip(bill.status),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BillDetailScreen(billId: bill.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
