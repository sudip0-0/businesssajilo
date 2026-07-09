import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/utils/money.dart';
import '../../../domain/models/bill.dart';
import '../../../features/billing/invoice_export_actions.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/product.dart';
import '../../../features/billing/bill_draft_line.dart';
import '../../../features/billing/bill_form_draft.dart';
import '../../../features/billing/bill_form_save.dart';
import '../../../features/billing/bill_form_validation.dart';
import '../../../features/billing/bill_payment_sheet.dart';
import '../../../features/billing/invalidate_billing.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../ui/web_search_field.dart';
import '../../../core/ui/adaptive_sheet.dart';
import '../../../core/testing/integration_keys.dart';

/// Web-native bill form layout with row-wise line items.
class WebBillFormContent extends ConsumerStatefulWidget {
  const WebBillFormContent({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<WebBillFormContent> createState() => WebBillFormContentState();
}

class WebBillFormContentState extends ConsumerState<WebBillFormContent> {
  final _draft = BillFormDraft(billDiscountText: '0');
  final _billDiscountController = TextEditingController(text: '0');
  final _remarksController = TextEditingController();
  final _productQueryController = TextEditingController();
  final _productSearchFocus = FocusNode();
  String _productQuery = '';
  bool _loading = false;

  @override
  void dispose() {
    _billDiscountController.dispose();
    _remarksController.dispose();
    _productQueryController.dispose();
    _productSearchFocus.dispose();
    super.dispose();
  }

  void _syncDraftFields() {
    _draft.billDiscountText = _billDiscountController.text;
  }

  void _focusProductSearch() {
    _productSearchFocus.requestFocus();
  }

  void _addProduct(Product product) {
    setState(() {
      _draft.addProduct(product);
      _productQuery = '';
      _productQueryController.clear();
    });
  }

  Future<void> saveDraft() => _save(forceStatus: BillStatus.due);

  Future<void> saveBill() => _save();

  Future<void> saveAndPrint() => _save(exportAfterSave: true);

  Future<Bill?> _save({
    BillStatus? forceStatus,
    bool exportAfterSave = false,
  }) async {
    final l10n = AppLocalizations.of(context);
    _syncDraftFields();
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

    BillPaymentResult? paymentResult;
    if (forceStatus == BillStatus.due) {
      paymentResult = duePaymentForDraft(_draft);
    } else {
      paymentResult = await showAdaptiveSheet<BillPaymentResult>(
        context: context,
        title: l10n.saveBill,
        child: BillPaymentSheet(
          grandTotal: _draft.grandTotal,
          initialCustomerId: _draft.customerId,
        ),
      );
    }
    if (paymentResult == null) return null;

    setState(() => _loading = true);
    Bill? savedBill;
    try {
      savedBill = await saveBillForm(
        ref.read(billingRefProvider),
        draft: _draft,
        payment: paymentResult,
        fallbackCustomerId: _draft.customerId,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.billSaved)));
        if (exportAfterSave) {
          await exportBillAfterSave(ref, context, savedBill);
        }
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
    return savedBill;
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
            .take(8)
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
                customerId: _draft.customerId,
                onCustomerChanged: (id) =>
                    setState(() => _draft.customerId = id),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WebBentoTile(
                      minHeight: 0,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.billLines,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                key: IntegrationKeys.billFormAddProduct,
                                onPressed: _focusProductSearch,
                                icon: Icon(PhosphorIconsRegular.plus, size: 16),
                                label: Text(l10n.addProduct),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _BillItemsTableHeader(l10n: l10n),
                          const SizedBox(height: 8),
                          if (_draft.lines.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                l10n.noBillLines,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: BsColors.outline),
                              ),
                            )
                          else
                            for (var i = 0; i < _draft.lines.length; i++)
                              _BillItemRow(
                                index: i,
                                line: _draft.lines[i],
                                l10n: l10n,
                                onChanged: () => setState(() {}),
                                onRemove: () =>
                                    setState(() => _draft.removeLineAt(i)),
                              ),
                          const SizedBox(height: 8),
                          _AddProductRow(
                            l10n: l10n,
                            controller: _productQueryController,
                            focusNode: _productSearchFocus,
                            onChanged: (v) => setState(
                              () => _productQuery = v.trim().toLowerCase(),
                            ),
                            suggestions: suggestions,
                            onProductSelected: _addProduct,
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
                          itemsTotal: _draft.itemsTotal,
                          billDiscountController: _billDiscountController,
                          grandTotal: _draft.grandTotal,
                          onDiscountChanged: () {
                            _syncDraftFields();
                            setState(() {});
                          },
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
                          children: [
                            remarks,
                            const SizedBox(height: 16),
                            summary,
                          ],
                        );
                      },
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BillItemsTableHeader extends StatelessWidget {
  const _BillItemsTableHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: BsColors.outline,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        SizedBox(width: 36, child: Text(l10n.sn, style: style)),
        Expanded(flex: 3, child: Text(l10n.productName, style: style)),
        SizedBox(width: 72, child: Text(l10n.qty, style: style)),
        SizedBox(width: 56, child: Text(l10n.unit, style: style)),
        SizedBox(width: 96, child: Text(l10n.rateRs, style: style)),
        SizedBox(width: 96, child: Text(l10n.amountRs, style: style)),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _BillItemRow extends StatelessWidget {
  const _BillItemRow({
    required this.index,
    required this.line,
    required this.l10n,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final BillDraftLine line;
  final AppLocalizations l10n;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: BsColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 36, child: Text('${index + 1}')),
          Expanded(
            flex: 3,
            child: Text(
              line.product.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: 72,
            child: TextFormField(
              initialValue: '${line.qty}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (v) {
                line.setQty(int.tryParse(v) ?? line.qty);
                onChanged();
              },
            ),
          ),
          SizedBox(width: 56, child: Text(line.product.unit)),
          SizedBox(
            width: 96,
            child: TextFormField(
              initialValue: formatNpr(
                Paisa(line.rate),
                showSymbol: false,
                showPaisa: false,
              ),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (v) {
                line.rate = parseNpr(v)?.value ?? line.rate;
                onChanged();
              },
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              formatNpr(Paisa(line.lineTotal), showPaisa: false),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: l10n.remove,
            icon: Icon(PhosphorIconsRegular.trash, color: BsColors.danger),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddProductRow extends StatelessWidget {
  const _AddProductRow({
    required this.l10n,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.suggestions,
    required this.onProductSelected,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final List<Product> suggestions;
  final ValueChanged<Product> onProductSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '…',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: BsColors.outline),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WebSearchField(
                    controller: controller,
                    focusNode: focusNode,
                    hint: l10n.filterProducts,
                    onChanged: onChanged,
                  ),
                  if (suggestions.isNotEmpty)
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(BsRadii.lg),
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
                              onTap: () => onProductSelected(p),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
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
              child: Text('AUTO', style: TextStyle(color: BsColors.outline)),
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
                    child: Text(
                      'AUTO',
                      style: TextStyle(color: BsColors.outline),
                    ),
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
                    labelText: l10n.billDiscount,
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

  Widget _summaryRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(formatNpr(Paisa(amount), showPaisa: false))],
    );
  }
}
