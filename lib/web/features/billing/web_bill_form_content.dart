import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/layout/bs_breakpoints.dart';
import '../../../core/ui/error_state.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/bill.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/product.dart';
import '../../../features/billing/bill_form_draft.dart';
import '../../../features/billing/bill_form_submit.dart';
import '../../../features/billing/bill_summary.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import 'web_bill_form_line_table.dart';
import 'web_bill_form_product_picker.dart';

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
    _syncDraftFields();
    setState(() => _loading = true);
    final bill = await submitBillForm(
      ref: ref,
      context: context,
      draft: _draft,
      forceStatus: forceStatus,
      fallbackCustomerId: _draft.customerId,
      exportAfterSave: exportAfterSave,
      onSaved: widget.onSaved,
      snackbarErrorColor: WebPalette.danger,
    );
    if (mounted) setState(() => _loading = false);
    return bill;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(productListProvider(_productQuery));
    final customersAsync = ref.watch(customerListProvider(''));
    final today = DateFormat.yMMMd().format(DateTime.now());

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(productListProvider(_productQuery)),
      ),
      data: (products) {
        final suggestions = _productQuery.isEmpty
            ? const <Product>[]
            : products.take(8).toList();

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
                          WebBillFormLineTable(
                            l10n: l10n,
                            lines: _draft.lines,
                            onLineChanged: () => setState(() {}),
                            onRemoveLine: (i) =>
                                setState(() => _draft.removeLineAt(i)),
                            onFocusProductSearch: _focusProductSearch,
                          ),
                          const SizedBox(height: 8),
                          WebBillFormProductPicker(
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
                        final wide =
                            constraints.maxWidth >= BsBreakpoints.tablet;
                        final summary = BillSummary(
                          style: BillSummaryStyle.card,
                          accentColor: WebPalette.navy,
                          cardBackground: WebPalette.navy.withValues(alpha: 0.04),
                          cardBorderColor: WebPalette.navy.withValues(alpha: 0.12),
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
        final wide = constraints.maxWidth >= BsBreakpoints.tablet;
        final customerField = customersAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l10n.loadingFailed),
          data: (customers) => DropdownButtonFormField<String?>(
            initialValue: customerId,
            decoration: InputDecoration(
              labelText: l10n.customerName,
              prefixIcon: const Icon(PhosphorIconsRegular.userPlus),
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
              child: const Text(
                'AUTO',
                style: TextStyle(color: WebPalette.inkSoft),
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
                    child: const Text(
                      'AUTO',
                      style: TextStyle(color: WebPalette.inkSoft),
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
