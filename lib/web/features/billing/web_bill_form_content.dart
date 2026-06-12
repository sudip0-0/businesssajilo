import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/utils/bill_totals.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/bills_repository.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/product.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/billing/bill_payment_sheet.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../ui/web_search_field.dart';
import '../../ui/web_sheet_bridge.dart';

class _DraftLine {
  _DraftLine({required this.product})
      : qty = 1,
        rate = product.referencePrice,
        discount = 0;

  final Product product;
  int qty;
  int rate;
  int discount;

  int get lineTotal =>
      lineTotalPaisa(qty: qty, ratePaisa: rate, discountPaisa: discount);
}

/// Web-native bill form layout inspired by reference invoice screens.
class WebBillFormContent extends ConsumerStatefulWidget {
  const WebBillFormContent({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<WebBillFormContent> createState() => WebBillFormContentState();
}

class WebBillFormContentState extends ConsumerState<WebBillFormContent> {
  final _lines = <_DraftLine>[];
  final _billDiscountController = TextEditingController(text: '0');
  final _remarksController = TextEditingController();
  final _productQueryController = TextEditingController();
  String? _customerId;
  String _productQuery = '';
  bool _loading = false;

  @override
  void dispose() {
    _billDiscountController.dispose();
    _remarksController.dispose();
    _productQueryController.dispose();
    super.dispose();
  }

  int get _itemsTotal => itemsTotalPaisa(_lines.map((l) => l.lineTotal));

  int get _billDiscount =>
      parseNpr(_billDiscountController.text)?.value ?? 0;

  int get _grandTotal => grandTotalPaisa(
        itemsTotal: _itemsTotal,
        billDiscountPaisa: _billDiscount,
      );

  void _addProduct(Product product) {
    final index = _lines.indexWhere((l) => l.product.id == product.id);
    setState(() {
      if (index >= 0) {
        _lines[index].qty += 1;
      } else {
        _lines.add(_DraftLine(product: product));
      }
      _productQuery = '';
      _productQueryController.clear();
    });
  }

  Future<void> saveDraft() => _save(forceStatus: BillStatus.due);

  Future<void> saveAndPrint() => _save();

  Future<void> _save({BillStatus? forceStatus}) async {
    final l10n = AppLocalizations.of(context);
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noBillLines),
          backgroundColor: BsColors.danger,
        ),
      );
      return;
    }

    BillPaymentResult? paymentResult;
    if (forceStatus == BillStatus.due) {
      paymentResult = BillPaymentResult(
        status: BillStatus.due,
        customerId: _customerId,
      );
    } else {
      paymentResult = await showAdaptiveSheet<BillPaymentResult>(
        context: context,
        title: l10n.saveBill,
        child: BillPaymentSheet(
          grandTotal: _grandTotal,
          initialCustomerId: _customerId,
        ),
      );
    }
    if (paymentResult == null) return;

    final memberId = ref.read(authProvider).value?.member?.id;
    if (memberId == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(billsRepositoryProvider).create(
            createdByMemberId: memberId,
            customerId: paymentResult.customerId ?? _customerId,
            status: paymentResult.status,
            itemsTotal: _itemsTotal,
            discount: _billDiscount,
            grandTotal: _grandTotal,
            lines: _lines
                .map(
                  (line) => BillLineInput(
                    productId: line.product.id,
                    nameSnapshot: line.product.name,
                    qty: line.qty,
                    rate: line.rate,
                    discount: line.discount,
                    lineTotal: line.lineTotal,
                  ),
                )
                .toList(),
            paymentMethod: paymentResult.paymentMethod,
            paymentRefNote: paymentResult.paymentRefNote,
            paymentAmount: paymentResult.paymentAmount,
          );

      if (paymentResult.customerId != null) {
        ref.invalidate(customerListProvider);
        ref.invalidate(totalDuesProvider);
      }
      ref.invalidate(billListProvider);
      ref.invalidate(todaysSalesProvider);
      ref.invalidate(todaysBillsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.billSaved)),
        );
        widget.onSaved?.call();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.actionFailed),
            backgroundColor: BsColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(productListProvider);
    final customersAsync = ref.watch(customerListProvider);
    final today = DateFormat.yMMMd().format(DateTime.now());

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(productListProvider),
      ),
      data: (products) {
        final suggestions = products
            .where((p) {
              if (_productQuery.isEmpty) return false;
              return p.name.toLowerCase().contains(_productQuery) ||
                  (p.sku?.toLowerCase().contains(_productQuery) ?? false);
            })
            .take(6)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WebBentoTile(
              minHeight: 0,
              padding: const EdgeInsets.all(20),
              child: WebFormHeaderRow(
                l10n: l10n,
                today: today,
                customersAsync: customersAsync,
                customerId: _customerId,
                onCustomerChanged: (id) => setState(() => _customerId = id),
              ),
            ),
            const SizedBox(height: 16),
            WebBentoTile(
              minHeight: 280,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.orders,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(PhosphorIconsRegular.plus, size: 16),
                        label: Text(l10n.addProduct),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 44,
                        dataRowMinHeight: 48,
                        columnSpacing: 16,
                        columns: [
                          DataColumn(label: Text(l10n.sn)),
                          DataColumn(label: Text(l10n.productName)),
                          DataColumn(label: Text(l10n.qty)),
                          DataColumn(label: Text(l10n.unit)),
                          DataColumn(label: Text(l10n.rateRs)),
                          DataColumn(label: Text(l10n.amountRs)),
                          const DataColumn(label: SizedBox(width: 40)),
                        ],
                        rows: [
                          for (var i = 0; i < _lines.length; i++)
                            _lineRow(context, l10n, i, _lines[i]),
                          DataRow(
                            cells: [
                              DataCell(Text('${_lines.length + 1}')),
                              DataCell(
                                SizedBox(
                                  width: 240,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      WebSearchField(
                                        controller: _productQueryController,
                                        hint: l10n.filterProducts,
                                        onChanged: (v) => setState(
                                          () => _productQuery =
                                              v.trim().toLowerCase(),
                                        ),
                                      ),
                                      if (suggestions.isNotEmpty)
                                        Material(
                                          elevation: 4,
                                          borderRadius: BorderRadius.circular(
                                            BsRadii.lg,
                                          ),
                                          child: Column(
                                            children: [
                                              for (final p in suggestions)
                                                ListTile(
                                                  dense: true,
                                                  title: Text(p.name),
                                                  subtitle: Text(
                                                    formatNpr(
                                                      Paisa(p.referencePrice),
                                                      showPaisa: false,
                                                    ),
                                                  ),
                                                  onTap: () => _addProduct(p),
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const DataCell(Text('—')),
                              const DataCell(Text('—')),
                              const DataCell(Text('—')),
                              const DataCell(Text('—')),
                              const DataCell(SizedBox.shrink()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 768;
                final summary = _BillSummaryPanel(
                  l10n: l10n,
                  itemsTotal: _itemsTotal,
                  billDiscountController: _billDiscountController,
                  grandTotal: _grandTotal,
                  onDiscountChanged: () => setState(() {}),
                );
                final remarks = TextField(
                  controller: _remarksController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.remarksTerms,
                    hintText: l10n.remarksTerms,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: remarks),
                      const SizedBox(width: 16),
                      SizedBox(width: 340, child: summary),
                    ],
                  );
                }
                return Column(
                  children: [remarks, const SizedBox(height: 16), summary],
                );
              },
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    );
  }

  DataRow _lineRow(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    _DraftLine line,
  ) {
    return DataRow(
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(line.product.name)),
        DataCell(
          SizedBox(
            width: 72,
            child: TextFormField(
              initialValue: '${line.qty}',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                line.qty = int.tryParse(v) ?? line.qty;
                if (line.qty < 1) line.qty = 1;
                setState(() {});
              },
            ),
          ),
        ),
        DataCell(Text(line.product.unit)),
        DataCell(
          SizedBox(
            width: 96,
            child: TextFormField(
              initialValue: formatNpr(
                Paisa(line.rate),
                showSymbol: false,
                showPaisa: false,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                line.rate = parseNpr(v)?.value ?? line.rate;
                setState(() {});
              },
            ),
          ),
        ),
        DataCell(
          Text(formatNpr(Paisa(line.lineTotal), showPaisa: false)),
        ),
        DataCell(
          IconButton(
            icon: Icon(PhosphorIconsRegular.trash, color: BsColors.danger),
            onPressed: () => setState(() => _lines.removeAt(index)),
          ),
        ),
      ],
    );
  }
}

class WebFormHeaderRow extends StatelessWidget {
  const WebFormHeaderRow({
    super.key,
    required this.l10n,
    required this.today,
    required this.customersAsync,
    required this.customerId,
    required this.onCustomerChanged,
  });

  final AppLocalizations l10n;
  final String today;
  final AsyncValue<List<Customer>> customersAsync;
  final String? customerId;
  final ValueChanged<String?> onCustomerChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 768;
        final customerField = customersAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l10n.loadingFailed),
          data: (customers) => DropdownButtonFormField<String?>(
            value: customerId,
            decoration: InputDecoration(
              labelText: l10n.customerName,
              prefixIcon: Icon(PhosphorIconsRegular.userPlus),
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.walkInCustomer),
              ),
              for (final c in customers)
                DropdownMenuItem(value: c.id, child: Text(c.shopName)),
            ],
            onChanged: onCustomerChanged,
          ),
        );

        final fields = [
          Expanded(flex: 2, child: customerField),
          const SizedBox(width: 16),
          Expanded(
            child: InputDecorator(
              decoration: InputDecoration(labelText: l10n.billDate),
              child: Text(today),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InputDecorator(
              decoration: InputDecoration(labelText: l10n.billNumber),
              child: Text(
                'AUTO',
                style: TextStyle(color: BsColors.outline),
              ),
            ),
          ),
        ];

        if (wide) {
          return Row(children: fields);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            customerField,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: l10n.billDate),
                    child: Text(today),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: l10n.billNumber),
                    child: Text('AUTO', style: TextStyle(color: BsColors.outline)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BillSummaryPanel extends StatelessWidget {
  const _BillSummaryPanel({
    required this.l10n,
    required this.itemsTotal,
    required this.billDiscountController,
    required this.grandTotal,
    required this.onDiscountChanged,
  });

  final AppLocalizations l10n;
  final int itemsTotal;
  final TextEditingController billDiscountController;
  final int grandTotal;
  final VoidCallback onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final discount = parseNpr(billDiscountController.text)?.value ?? 0;
    final taxable = itemsTotal - discount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BsColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(BsRadii.lg),
        border: Border.all(color: BsColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryRow(l10n.subtotal, itemsTotal),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: billDiscountController,
                  decoration: InputDecoration(
                    labelText: l10n.discountPercent,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onDiscountChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                discount > 0
                    ? '- ${formatNpr(Paisa(discount), showPaisa: false)}'
                    : '—',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _summaryRow(l10n.taxableAmount, taxable),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.grandTotal,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                formatNpr(Paisa(grandTotal), showPaisa: false),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: BsColors.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(formatNpr(Paisa(amount), showPaisa: false)),
      ],
    );
  }
}
