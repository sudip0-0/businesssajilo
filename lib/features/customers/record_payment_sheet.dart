import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/ui/sheet_select_field.dart';
import '../../core/ui/submit_action.dart';
import '../../core/utils/money.dart';
import '../../core/utils/payment_method_label.dart';
import '../../domain/enums.dart';
import '../billing/invalidate_billing.dart';
import '../billing/payment_allocation.dart';
import '../billing/providers.dart';
import '../billing/record_customer_payment.dart';
import 'providers.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({
    super.key,
    this.customerId,
    this.customerName,
    this.showCustomerPicker = false,
  });

  final String? customerId;
  final String? customerName;
  final bool showCustomerPicker;

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();
  final _refController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  PaymentAllocateMode _allocation = PaymentAllocateMode.account;
  String? _selectedCustomerId;
  String? _billId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final amount = parseNpr(_amountController.text);
    final error = validateRecordPayment(
      customerId: _selectedCustomerId,
      amountPaisa: amount?.value,
    );
    if (error != null) {
      final message = switch (error) {
        RecordPaymentValidationError.amountRequired => l10n.amountRequired,
        RecordPaymentValidationError.amountNotPositive =>
          l10n.amountMustBePositive,
        RecordPaymentValidationError.noCustomer => l10n.selectCustomer,
      };
      showBsSnackBar(
        context,
        message: message,
        backgroundColor: BsColors.danger,
      );
      return;
    }

    final customerId = _selectedCustomerId!;
    final refNote = _refController.text.trim();

    setState(() => _loading = true);
    await runSubmitAction(
      context,
      action: () async {
        await recordCustomerPayment(
          ref.read(billingRefProvider),
          customerId: customerId,
          amountPaisa: amount!.value,
          method: _method,
          refNote: refNote.isEmpty ? null : refNote,
          allocation: PaymentAllocation(mode: _allocation, billId: _billId),
        );
        if (mounted) Navigator.pop(context, true);
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final customersAsync = widget.showCustomerPicker
        ? ref.watch(customerListProvider(''))
        : null;
    final selectedCustomerAsync = _selectedCustomerId == null
        ? null
        : ref.watch(customerDetailProvider(_selectedCustomerId!));
    final balanceDue = selectedCustomerAsync?.value?.balanceDue;
    final amountValue = parseNpr(_amountController.text)?.value;
    final overpayment =
        balanceDue != null && amountValue != null && amountValue > balanceDue;

    return Material(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.recordPayment,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.customerName != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.customerName!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 16),
              if (widget.showCustomerPicker)
                customersAsync!.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(l10n.loadingFailed),
                  data: (customers) => SheetSelectField<String>(
                    label: l10n.selectCustomer,
                    value: _selectedCustomerId,
                    items: customers.map((c) => c.id).toList(),
                    itemLabel: (id) =>
                        customers.firstWhere((c) => c.id == id).shopName,
                    onChanged: (v) => setState(() {
                      _selectedCustomerId = v;
                      _billId = null;
                    }),
                  ),
                ),
              if (balanceDue != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.currentBalance}: ${formatNpr(Paisa(balanceDue), showPaisa: false)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
              const SizedBox(height: 12),
              Text(l10n.allocateToAccount),
              const SizedBox(height: 8),
              SheetSelectField<PaymentAllocateMode>(
                label: l10n.paymentAllocation,
                value: _allocation,
                items: PaymentAllocateMode.values,
                itemLabel: (mode) => switch (mode) {
                  PaymentAllocateMode.account => l10n.allocateToAccount,
                  PaymentAllocateMode.oldestFirst => l10n.allocateOldestFirst,
                  PaymentAllocateMode.bill => l10n.allocateToBill,
                },
                onChanged: (v) => setState(() => _allocation = v),
              ),
              if (_allocation == PaymentAllocateMode.bill &&
                  _selectedCustomerId != null) ...[
                const SizedBox(height: 12),
                ref
                    .watch(openBillsForCustomerProvider(_selectedCustomerId!))
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => Text(l10n.loadingFailed),
                      data: (bills) => SheetSelectField<String>(
                        label: l10n.selectBill,
                        value: _billId,
                        items: bills.map((b) => b.id).toList(),
                        itemLabel: (id) {
                          final b = bills.firstWhere((bill) => bill.id == id);
                          return '${b.billNo} · ${formatNpr(Paisa(b.grandTotal), showPaisa: false)}';
                        },
                        onChanged: (v) => setState(() => _billId = v),
                      ),
                    ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocus,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.paymentAmount),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              if (overpayment) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.overpaymentWarning,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: BsColors.accent),
                ),
              ],
              const SizedBox(height: 12),
              SheetSelectField<PaymentMethod>(
                label: l10n.paymentMethod,
                value: _method,
                items: PaymentMethod.values,
                itemLabel: (m) => paymentMethodLabel(l10n, m),
                onChanged: (v) => setState(() => _method = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _refController,
                decoration: InputDecoration(labelText: l10n.paymentRef),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
