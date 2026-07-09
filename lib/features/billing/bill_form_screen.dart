import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/stock_badge.dart';
import '../../core/utils/money.dart';
import '../../domain/models/bill.dart';
import 'invoice_export_actions.dart';
import '../../domain/models/product.dart';
import '../../core/ui/bs_success_button.dart';
import '../inventory/product_image.dart';
import '../inventory/providers.dart';
import '../../core/ui/adaptive_sheet.dart';
import 'bill_draft_line.dart';
import 'bill_form_draft.dart';
import 'bill_form_save.dart';
import 'bill_form_validation.dart';
import 'bill_payment_sheet.dart';
import 'invalidate_billing.dart';

class BillFormScreen extends ConsumerStatefulWidget {
  const BillFormScreen({super.key, this.embedded = false, this.onSaved});

  final bool embedded;
  final VoidCallback? onSaved;

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  final _draft = BillFormDraft();
  final _billDiscountController = TextEditingController();
  String _query = '';
  bool _loading = false;

  /// On narrow screens, show cart review after the first line is added.
  bool _showCart = false;

  @override
  void dispose() {
    _billDiscountController.dispose();
    super.dispose();
  }

  void _syncDiscountText() {
    _draft.billDiscountText = _billDiscountController.text;
  }

  void _addProduct(Product product) {
    setState(() {
      _draft.addProduct(product);
      _showCart = true;
    });
  }

  Future<Bill?> _save({bool exportAfterSave = false}) async {
    final l10n = AppLocalizations.of(context);
    _syncDiscountText();
    final validationError = validateBillForm(_draft);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billFormValidationMessage(l10n, validationError)),
          backgroundColor: BsColors.danger,
        ),
      );
      return null;
    }

    final paymentResult = await showAdaptiveSheet<BillPaymentResult>(
      context: context,
      title: l10n.saveBill,
      child: BillPaymentSheet(grandTotal: _draft.grandTotal),
    );
    // Print/share is offered after save via exportBillAfterSave when requested.
    if (paymentResult == null) return null;

    setState(() => _loading = true);
    Bill? savedBill;
    try {
      savedBill = await saveBillForm(
        ref.read(billingRefProvider),
        draft: _draft,
        payment: paymentResult,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.billSaved)));
        if (exportAfterSave) {
          await exportBillAfterSave(ref, context, savedBill);
        }
        if (!mounted) return savedBill;
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          Navigator.pop(context, true);
        }
      }
      return savedBill;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.actionFailed),
            backgroundColor: BsColors.danger,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(productListProvider(_query));

    final body = productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(productListProvider(_query)),
      ),
      data: (products) {
        final narrow = MediaQuery.sizeOf(context).width < 720;
        final showPicker = !narrow || !_showCart || _draft.lines.isEmpty;
        final showCart = !narrow || _showCart;

        Widget productPicker() => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.filterProducts,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
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
        );

        Widget cartPane() => Column(
          children: [
            if (narrow && _draft.lines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showCart = false),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addProduct),
                  ),
                ),
              ),
            Expanded(
              child: _draft.lines.isEmpty
                  ? Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showCart = false),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.noBillLines),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _draft.lines.length,
                      itemBuilder: (context, index) {
                        final line = _draft.lines[index];
                        return _LineEditor(
                          line: line,
                          onChanged: () => setState(() {}),
                          onRemove: () => setState(() {
                            _draft.removeLineAt(index);
                            if (_draft.lines.isEmpty) _showCart = false;
                          }),
                        );
                      },
                    ),
            ),
            _TotalsBar(
              itemsTotal: _draft.itemsTotal,
              billDiscountController: _billDiscountController,
              grandTotal: _draft.grandTotal,
              onDiscountChanged: () {
                _syncDiscountText();
                setState(() {});
              },
            ),
          ],
        );

        if (narrow) {
          return Column(
            children: [
              Expanded(child: showPicker ? productPicker() : cartPane()),
              if (widget.embedded)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: _loading
                          ? null
                          : () {
                              if (showPicker && _draft.lines.isNotEmpty) {
                                setState(() => _showCart = true);
                                return;
                              }
                              _save();
                            },
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              showPicker && _draft.lines.isNotEmpty
                                  ? l10n.reviewAndSave
                                  : l10n.saveBill,
                            ),
                    ),
                  ),
                ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              flex: _draft.lines.isEmpty ? 1 : 2,
              child: productPicker(),
            ),
            const Divider(height: 1),
            Expanded(
              flex: _draft.lines.isEmpty ? 0 : 3,
              child: showCart ? cartPane() : const SizedBox.shrink(),
            ),
            if (widget.embedded)
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
                        : Text(l10n.saveBill),
                  ),
                ),
              ),
          ],
        );
      },
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createNewBill),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BsSuccessButton(
                onPressed: _loading
                    ? null
                    : () {
                        final narrow = MediaQuery.sizeOf(context).width < 720;
                        if (narrow && !_showCart && _draft.lines.isNotEmpty) {
                          setState(() => _showCart = true);
                          return;
                        }
                        _save();
                      },
                label: l10n.saveBill,
              ),
              if (_draft.lines.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _save(exportAfterSave: true),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(l10n.printAndSave),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LineEditor extends StatefulWidget {
  const _LineEditor({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final BillDraftLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final line = widget.line;
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
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                tooltip: l10n.edit,
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.remove,
                onPressed: widget.onRemove,
              ),
            ],
          ),
          Row(
            children: [
              QtyStepper(
                value: line.qty,
                min: 1,
                onChanged: (v) {
                  line.setQty(v);
                  widget.onChanged();
                },
              ),
              const Spacer(),
              Text(
                formatNpr(Paisa(line.lineTotal), showPaisa: false),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          if (_expanded) ...[
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
                widget.onChanged();
              },
            ),
            const SizedBox(height: 4),
            Text(l10n.lineDiscount),
            TextFormField(
              initialValue: line.discount == 0
                  ? ''
                  : formatNpr(
                      Paisa(line.discount),
                      showSymbol: false,
                      showPaisa: false,
                    ),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                errorText: line.discountValid ? null : l10n.discountExceedsLine,
              ),
              onChanged: (v) {
                line.discount = parseNpr(v)?.value ?? 0;
                widget.onChanged();
              },
            ),
          ],
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
    final discount = parseNpr(billDiscountController.text)?.value ?? 0;
    final taxable = itemsTotal - discount;

    return Container(
      decoration: BoxDecoration(
        color: BsColors.primary.withValues(alpha: 0.04),
        border: const Border(top: BorderSide(color: BsColors.border)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryRow(context, l10n.subtotal, itemsTotal),
          const SizedBox(height: 8),
          TextFormField(
            controller: billDiscountController,
            decoration: InputDecoration(
              labelText: l10n.billDiscount,
              isDense: true,
              errorText: () {
                if (discount < 0 || discount > itemsTotal) {
                  return l10n.discountExceedsItems;
                }
                return null;
              }(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => onDiscountChanged(),
          ),
          const SizedBox(height: 8),
          _summaryRow(context, l10n.taxableAmount, taxable),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.grandTotal,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

  Widget _summaryRow(BuildContext context, String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(formatNpr(Paisa(amount), showPaisa: false))],
    );
  }
}
