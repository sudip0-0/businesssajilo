import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/product.dart';
import 'bill_form_customer_field.dart';
import 'bill_form_draft.dart';
import 'bill_form_leave_confirm.dart';
import 'bill_form_line_editor.dart';
import 'bill_form_product_picker.dart';
import 'bill_form_submit.dart';
import 'bill_summary.dart';
import 'copy_last_bill.dart';
import 'providers.dart';
import 'validate_bill_payment.dart';

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
  bool _loading = false;
  bool _isCustomerSearchActive = false;
  Customer? _selectedCustomer;

  @override
  void dispose() {
    _billDiscountController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _draft.lines.isNotEmpty ||
      _draft.customerId != null ||
      (_draft.guestName?.trim().isNotEmpty ?? false) ||
      _draft.billDiscount != 0;

  void _syncDirtyFlag() {
    ref.read(billFormDirtyProvider.notifier).setDirty(_isDirty);
  }

  Future<void> _copyLastBill() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final bill = await fetchLatestBillWithItems(
        ref.read(billsRepositoryProvider),
      );
      if (!mounted) return;
      if (bill == null) {
        showBsSnackBar(context, message: l10n.noBillsToCopy);
        return;
      }
      final catalog = await productsForBillItems(
        products: ref.read(productsRepositoryProvider),
        bill: bill,
      );
      Customer? customer;
      if (bill.customerId != null) {
        try {
          customer = await ref
              .read(customersRepositoryProvider)
              .get(bill.customerId!);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _draft.loadFromBill(bill, catalog);
        _billDiscountController.text = _draft.billDiscountText;
        _selectedCustomer = customer;
      });
      _syncDirtyFlag();
      if (_draft.lines.isEmpty) {
        showBsSnackBar(context, message: l10n.noBillLines);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncDiscountText() {
    _draft.billDiscountText = _billDiscountController.text;
  }

  void _addProduct(Product product) {
    setState(() => _draft.addProduct(product));
    _syncDirtyFlag();
  }

  Future<void> _openProductPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return BillFormProductPickerSheet(
          onSelected: (product) {
            _addProduct(product);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  Future<Bill?> _save({BillStatus? forceStatus}) async {
    _syncDiscountText();
    if (forceStatus == BillStatus.due) {
      final l10n = AppLocalizations.of(context);
      final error = validateBillPayment(
        status: BillStatus.due,
        grandTotal: _draft.grandTotal,
        walkIn: _selectedCustomer == null,
        customerId: _selectedCustomer?.id,
      );
      if (error != null) {
        showBsSnackBar(
          context,
          message: error == BillPaymentValidationError.walkInCreditNotAllowed
              ? l10n.selectCustomerForCredit
              : l10n.selectCustomer,
          backgroundColor: BsColors.danger,
        );
        return null;
      }
    }

    setState(() => _loading = true);
    final bill = await submitBillForm(
      ref: ref,
      context: context,
      draft: _draft,
      forceStatus: forceStatus,
      initialCustomerName: _selectedCustomer?.shopName,
      onSaved: () {
        ref.read(billFormDirtyProvider.notifier).clear();
        widget.onSaved?.call();
      },
      popOnSuccess: widget.onSaved == null && !widget.embedded,
    );
    if (mounted) setState(() => _loading = false);
    return bill;
  }

  Future<void> _onWillPop() async {
    if (!_isDirty) {
      ref.read(billFormDirtyProvider.notifier).clear();
      return;
    }
    final leave = await confirmLeaveUnsavedBill(context);
    if (leave && mounted) {
      ref.read(billFormDirtyProvider.notifier).clear();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = _buildBody(l10n);

    if (widget.embedded) {
      return Column(
        children: [
          Expanded(child: body),
          _saveBar(l10n),
        ],
      );
    }
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          ref.read(billFormDirtyProvider.notifier).clear();
          return;
        }
        await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.createNewBill,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: l10n.more,
              onSelected: (value) {
                if (value == 'copy') _copyLastBill();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: !_loading,
                  value: 'copy',
                  child: Text(l10n.copyLastBill),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            body,
            if (_loading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
        bottomNavigationBar: _saveBar(l10n),
      ),
    );
  }

  Widget _saveBar(AppLocalizations l10n) {
    const compactSize = Size(0, 44);
    final outlinedStyle = OutlinedButton.styleFrom(
      minimumSize: compactSize,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BsSpacing.lg,
          4,
          BsSpacing.lg,
          BsSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: outlinedStyle,
                onPressed: _loading
                    ? null
                    : () => _save(forceStatus: BillStatus.due),
                child: Text(
                  l10n.saveAsDue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: compactSize),
                onPressed: _loading ? null : () => _save(),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              BsSpacing.lg,
              BsSpacing.sm,
              BsSpacing.lg,
              BsSpacing.sm,
            ),
            children: [
              BillCustomerSearchField(
                selectedCustomer: _selectedCustomer,
                selectedName: _selectedCustomer?.shopName ?? _draft.guestName,
                onCustomerSelected: (customer) {
                  setState(() {
                    _selectedCustomer = customer;
                    _draft.customerId = customer?.id;
                    if (customer != null) {
                      _draft.guestName = null;
                    }
                  });
                  _syncDirtyFlag();
                },
                onTextChanged: (text) {
                  if (_selectedCustomer == null) {
                    _draft.guestName = text.trim().isEmpty ? null : text.trim();
                    _syncDirtyFlag();
                  }
                },
                onSearchActiveChanged: (active) {
                  setState(() => _isCustomerSearchActive = active);
                },
              ),
              const SizedBox(height: 12),
              Text(
                l10n.billItems,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_draft.lines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: BsSpacing.md),
                  child: Text(
                    l10n.noBillLines,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: BsColors.outline),
                  ),
                )
              else
                for (var i = 0; i < _draft.lines.length; i++)
                  BillFormLineEditor(
                    key: ValueKey(_draft.lines[i].product.id),
                    line: _draft.lines[i],
                    onChanged: () {
                      setState(() {});
                      _syncDirtyFlag();
                    },
                    onRemove: () {
                      setState(() => _draft.removeLineAt(i));
                      _syncDirtyFlag();
                    },
                  ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _loading ? null : _openProductPicker,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addItem),
                ),
              ),
            ],
          ),
        ),
        if (!_isCustomerSearchActive)
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: BsColors.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BsSpacing.lg,
                BsSpacing.sm,
                BsSpacing.lg,
                BsSpacing.xs,
              ),
              child: BillSummary(
                style: BillSummaryStyle.checkout,
                itemsTotal: _draft.itemsTotal,
                billDiscountController: _billDiscountController,
                grandTotal: _draft.grandTotal,
                onDiscountChanged: () {
                  _syncDiscountText();
                  setState(() {});
                  _syncDirtyFlag();
                },
              ),
            ),
          ),
      ],
    );
  }
}
