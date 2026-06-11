import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/stock_badge.dart';
import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/bills_repository.dart';
import '../../domain/models/product.dart';
import '../auth/providers/auth_provider.dart';
import '../customers/providers.dart';
import '../inventory/product_image.dart';
import '../inventory/providers.dart';
import 'bill_payment_sheet.dart';

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

class BillFormScreen extends ConsumerStatefulWidget {
  const BillFormScreen({super.key});

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  final _lines = <_DraftLine>[];
  final _billDiscountController = TextEditingController();
  String _query = '';
  bool _loading = false;

  @override
  void dispose() {
    _billDiscountController.dispose();
    super.dispose();
  }

  int get _itemsTotal => itemsTotalPaisa(_lines.map((l) => l.lineTotal));

  int get _billDiscount =>
      parseNpr(_billDiscountController.text)?.value ?? 0;

  int get _grandTotal =>
      grandTotalPaisa(itemsTotal: _itemsTotal, billDiscountPaisa: _billDiscount);

  void _addProduct(Product product) {
    final index = _lines.indexWhere((l) => l.product.id == product.id);
    if (index >= 0) {
      setState(() => _lines[index].qty += 1);
    } else {
      setState(() => _lines.add(_DraftLine(product: product)));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noBillLines), backgroundColor: BsColors.danger),
      );
      return;
    }
    if (_grandTotal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.amountMustBePositive),
          backgroundColor: BsColors.danger,
        ),
      );
      return;
    }

    final paymentResult = await showModalBottomSheet<BillPaymentResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BillPaymentSheet(grandTotal: _grandTotal),
    );
    if (paymentResult == null) return;

    final memberId = ref.read(authProvider).value?.member?.id;
    if (memberId == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(billsRepositoryProvider).create(
            createdByMemberId: memberId,
            customerId: paymentResult.customerId,
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
        ref.invalidate(customerDetailProvider(paymentResult.customerId!));
        ref.invalidate(customerLedgerProvider(paymentResult.customerId!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.billSaved)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: BsColors.danger),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newBill)),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (products) {
          final filtered = products.where((p) {
            if (_query.isEmpty) return true;
            return p.name.toLowerCase().contains(_query.toLowerCase()) ||
                (p.sku?.toLowerCase().contains(_query.toLowerCase()) ?? false);
          }).toList();

          return Column(
            children: [
              Expanded(
                flex: _lines.isEmpty ? 1 : 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l10n.filterProducts,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return ListTile(
                            leading: ProductImage(storagePath: product.imageUrl),
                            title: Text(product.name),
                            subtitle: Text(
                              formatNpr(
                                Paisa(product.referencePrice),
                                showPaisa: false,
                              ),
                            ),
                            trailing: StockBadge(product: product),
                            onTap: () => _addProduct(product),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                flex: _lines.isEmpty ? 0 : 3,
                child: _lines.isEmpty
                    ? Center(child: Text(l10n.noBillLines))
                    : ListView.builder(
                        itemCount: _lines.length,
                        itemBuilder: (context, index) {
                          final line = _lines[index];
                          return _LineEditor(
                            line: line,
                            onChanged: () => setState(() {}),
                            onRemove: () => setState(() => _lines.removeAt(index)),
                          );
                        },
                      ),
              ),
              _TotalsBar(
                itemsTotal: _itemsTotal,
                billDiscountController: _billDiscountController,
                grandTotal: _grandTotal,
                onDiscountChanged: () => setState(() {}),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.reviewAndSave),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LineEditor extends StatelessWidget {
  const _LineEditor({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final _DraftLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.product.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ],
          ),
          Row(
            children: [
              QtyStepper(
                value: line.qty,
                min: 1,
                onChanged: (v) {
                  line.qty = v;
                  onChanged();
                },
              ),
              const Spacer(),
              Text(
                formatNpr(Paisa(line.lineTotal), showPaisa: false),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.rate),
          TextFormField(
            initialValue: formatNpr(
              Paisa(line.rate),
              showSymbol: false,
              showPaisa: false,
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              line.rate = parseNpr(v)?.value ?? line.rate;
              onChanged();
            },
          ),
          const SizedBox(height: 4),
          Text(l10n.lineDiscount),
          TextFormField(
            initialValue: line.discount == 0
                ? ''
                : formatNpr(Paisa(line.discount), showSymbol: false, showPaisa: false),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              line.discount = parseNpr(v)?.value ?? 0;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({
    required this.itemsTotal,
    required this.billDiscountController,
    required this.grandTotal,
    required this.onDiscountChanged,
  });

  final int itemsTotal;
  final TextEditingController billDiscountController;
  final int grandTotal;
  final VoidCallback onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.total),
                Text(formatNpr(Paisa(itemsTotal), showPaisa: false)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: billDiscountController,
              decoration: InputDecoration(labelText: l10n.billDiscount),
              keyboardType: TextInputType.number,
              onChanged: (_) => onDiscountChanged(),
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }
}
