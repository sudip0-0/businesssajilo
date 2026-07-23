import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ui/bill_status_chip.dart';
import '../../../../core/utils/money.dart';
import '../../../../domain/enums.dart';
import '../../../../domain/models/bill.dart';
import '../../../theme/web_palette.dart';
import '../../../theme/web_typography.dart';

/// Today's bills table for the owner dashboard.
class WebDashboardTransactionsTable extends StatelessWidget {
  const WebDashboardTransactionsTable({super.key, required this.bills});

  final List<Bill> bills;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeFmt = DateFormat.jm();

    if (bills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            l10n.noSalesInPeriod,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: WebPalette.inkSoft),
          ),
        ),
      );
    }

    final headerStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: WebPalette.inkSoft,
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 720.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth < minTableWidth
                  ? minTableWidth
                  : constraints.maxWidth,
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(72),
                1: FlexColumnWidth(2.4),
                2: FlexColumnWidth(1.1),
                3: FlexColumnWidth(1.1),
                4: FlexColumnWidth(1.3),
                5: FlexColumnWidth(1.2),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: WebPalette.hairline),
                    ),
                  ),
                  children: [
                    _headerCell(l10n.sn, headerStyle),
                    _headerCell(l10n.customerName, headerStyle),
                    _headerCell(l10n.time, headerStyle),
                    _headerCell(l10n.payment, headerStyle),
                    _headerCell(l10n.amountNpr, headerStyle),
                    _headerCell(l10n.status, headerStyle),
                  ],
                ),
                for (final bill in bills)
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: WebPalette.hairline),
                      ),
                    ),
                    children: [
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(
                          '#${bill.billNo.split('-').last}',
                          style: WebTypography.mono(
                            fontSize: 12,
                            color: WebPalette.inkSoft,
                          ),
                        ),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(
                          bill.customerShopName ?? l10n.walkInCustomer,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(
                          bill.createdAt != null
                              ? timeFmt.format(bill.createdAt!.toLocal())
                              : '—',
                        ),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(_paymentLabel(bill.status, l10n)),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Text(
                          formatNpr(Paisa(bill.grandTotal), showPaisa: false),
                          style: WebTypography.mono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: WebPalette.ink,
                          ),
                        ),
                      ),
                      _dataCell(
                        onTap: () => context.go('/owner/billing/${bill.id}'),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: BillStatusChip(bill.status),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerCell(String label, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Text(label, style: style),
    );
  }

  Widget _dataCell({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: child,
        ),
      ),
    );
  }

  String _paymentLabel(BillStatus status, AppLocalizations l10n) {
    return switch (status) {
      BillStatus.paid => l10n.paymentMethodCash,
      BillStatus.partial => l10n.partial,
      BillStatus.due => l10n.due,
    };
  }
}
