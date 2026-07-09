import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../core/utils/payment_method_label.dart';
import '../../data/repositories/payments_repository.dart';
import '../../domain/enums.dart';
import '../auth/providers/auth_provider.dart';
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
  final _refController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  String? _selectedCustomerId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final amount = parseNpr(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.amountRequired),
          backgroundColor: BsColors.danger,
        ),
      );
      return;
    }
    if (amount.value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.amountMustBePositive),
          backgroundColor: BsColors.danger,
        ),
      );
      return;
    }
    final customerId = _selectedCustomerId;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectCustomer),
          backgroundColor: BsColors.danger,
        ),
      );
      return;
    }
    final memberId = ref.read(authProvider).value?.member?.id;
    if (memberId == null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(paymentsRepositoryProvider)
          .record(
            customerId: customerId,
            amount: amount.value,
            method: _method,
            refNote: _refController.text.trim().isEmpty
                ? null
                : _refController.text.trim(),
            receivedByMemberId: memberId,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).actionFailed),
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final customersAsync = widget.showCustomerPicker
        ? ref.watch(customerListProvider)
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
                  data: (customers) => DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: l10n.selectCustomer),
                    initialValue: _selectedCustomerId,
                    items: customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.shopName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCustomerId = v),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
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
              DropdownButtonFormField<PaymentMethod>(
                decoration: InputDecoration(labelText: l10n.paymentMethod),
                initialValue: _method,
                items: PaymentMethod.values
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(paymentMethodLabel(l10n, m)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _method = v);
                },
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
