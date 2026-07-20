import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../core/utils/payment_method_label.dart';
import '../../domain/enums.dart';
import '../billing/invalidate_billing.dart';
import '../billing/record_customer_sale.dart';

class RecordSaleSheet extends ConsumerStatefulWidget {
  const RecordSaleSheet({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String customerName;

  @override
  ConsumerState<RecordSaleSheet> createState() => _RecordSaleSheetState();
}

class _RecordSaleSheetState extends ConsumerState<RecordSaleSheet> {
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  bool _paidNow = false;
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final amount = parseNpr(_amountController.text);
    final error = validateRecordSale(
      customerId: widget.customerId,
      amountPaisa: amount?.value,
    );
    if (error != null) {
      final message = switch (error) {
        RecordSaleValidationError.amountRequired => l10n.amountRequired,
        RecordSaleValidationError.amountNotPositive =>
          l10n.amountMustBePositive,
        RecordSaleValidationError.noCustomer => l10n.selectCustomer,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: BsColors.danger),
      );
      return;
    }

    final refNote = _refController.text.trim();

    setState(() => _loading = true);
    try {
      await recordCustomerSale(
        ref.read(billingRefProvider),
        customerId: widget.customerId,
        amountPaisa: amount!.value,
        refNote: refNote.isEmpty ? null : refNote,
        paidNow: _paidNow,
        paymentMethod: _method,
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

    return Material(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.recordSale,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.customerName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n.saleAmount,
                  prefixText: 'Rs. ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _refController,
                decoration: InputDecoration(labelText: l10n.saleNote),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.paidNow),
                subtitle: Text(l10n.paidNowHint),
                value: _paidNow,
                onChanged: (v) => setState(() => _paidNow = v),
              ),
              if (_paidNow) ...[
                const SizedBox(height: 4),
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
              ],
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
