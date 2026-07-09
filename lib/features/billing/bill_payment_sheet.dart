import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../core/utils/payment_method_label.dart';
import '../../domain/enums.dart';
import '../../domain/models/customer.dart';
import '../customers/providers.dart';
import 'validate_bill_payment.dart';

export 'bill_payment_result.dart';

class BillPaymentSheet extends ConsumerStatefulWidget {
  const BillPaymentSheet({
    super.key,
    required this.grandTotal,
    this.initialCustomerId,
  });

  final int grandTotal;
  final String? initialCustomerId;

  @override
  ConsumerState<BillPaymentSheet> createState() => _BillPaymentSheetState();
}

class _BillPaymentSheetState extends ConsumerState<BillPaymentSheet> {
  BillStatus _status = BillStatus.paid;
  bool _walkIn = false;
  String? _customerId;
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _customerSearchController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    _walkIn = widget.initialCustomerId == null;
    _amountController.text = formatNpr(
      Paisa(widget.grandTotal),
      showSymbol: false,
      showPaisa: false,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);

    final partialAmount = _status == BillStatus.partial
        ? parseNpr(_amountController.text)?.value
        : null;

    final error = validateBillPayment(
      status: _status,
      grandTotal: widget.grandTotal,
      walkIn: _walkIn,
      customerId: _customerId,
      partialAmountPaisa: partialAmount,
    );
    if (error != null) {
      _showError(_paymentValidationMessage(l10n, error));
      return;
    }

    final refNote = _refController.text.trim();
    Navigator.pop(
      context,
      buildBillPaymentResult(
        status: _status,
        grandTotal: widget.grandTotal,
        walkIn: _walkIn,
        customerId: _customerId,
        partialAmountPaisa: partialAmount,
        paymentMethod: _method,
        paymentRefNote: refNote.isEmpty ? null : refNote,
      ),
    );
  }

  String _paymentValidationMessage(
    AppLocalizations l10n,
    BillPaymentValidationError error,
  ) {
    return switch (error) {
      BillPaymentValidationError.amountRequired => l10n.amountRequired,
      BillPaymentValidationError.amountNotPositive => l10n.amountMustBePositive,
      BillPaymentValidationError.amountExceedsTotal => l10n.amountExceedsTotal,
      BillPaymentValidationError.selectCustomer => l10n.selectCustomer,
      BillPaymentValidationError.walkInCreditNotAllowed =>
        l10n.selectCustomerForCredit,
    };
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: BsColors.danger),
    );
  }

  List<Customer> _filterCustomers(List<Customer> customers, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return customers;
    return customers.where((c) {
      return c.shopName.toLowerCase().contains(q) ||
          (c.contactName?.toLowerCase().contains(q) ?? false) ||
          (c.phone?.contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final searchQuery = _customerSearchController.text.trim();
    final customersAsync = ref.watch(customerListProvider(searchQuery));

    // Prefill search label once customers load.
    customersAsync.whenData((customers) {
      if (_customerId != null && _customerSearchController.text.isEmpty) {
        final match = customers.where((c) => c.id == _customerId).firstOrNull;
        if (match != null) {
          _customerSearchController.text = match.shopName;
        }
      }
    });

    return Material(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.reviewAndSave,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.grandTotal}: ${formatNpr(Paisa(widget.grandTotal), showPaisa: false)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(l10n.selectPaymentStatus),
              const SizedBox(height: 8),
              SegmentedButton<BillStatus>(
                segments: [
                  ButtonSegment(value: BillStatus.paid, label: Text(l10n.paid)),
                  ButtonSegment(
                    value: BillStatus.partial,
                    label: Text(l10n.partial),
                  ),
                  ButtonSegment(value: BillStatus.due, label: Text(l10n.due)),
                ],
                selected: {_status},
                onSelectionChanged: (s) {
                  setState(() {
                    _status = s.first;
                    if (_status == BillStatus.paid) {
                      _amountController.text = formatNpr(
                        Paisa(widget.grandTotal),
                        showSymbol: false,
                        showPaisa: false,
                      );
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.walkIn),
                value: _walkIn,
                onChanged: (v) => setState(() {
                  _walkIn = v;
                  if (v) {
                    _customerId = null;
                    _customerSearchController.clear();
                  }
                }),
              ),
              if (!_walkIn)
                customersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(l10n.loadingFailed),
                  data: (customers) => Autocomplete<Customer>(
                    displayStringForOption: (c) => c.shopName,
                    optionsBuilder: (textEditingValue) {
                      // Provider already searched; keep a light client filter
                      // for the Autocomplete keystroke before rebuild.
                      return _filterCustomers(customers, textEditingValue.text);
                    },
                    onSelected: (c) {
                      setState(() {
                        _customerId = c.id;
                        _customerSearchController.text = c.shopName;
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          // Keep external controller in sync for prefill.
                          if (controller.text.isEmpty &&
                              _customerSearchController.text.isNotEmpty) {
                            controller.text = _customerSearchController.text;
                          }
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: l10n.selectCustomer,
                              hintText: l10n.filterCustomers,
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (v) {
                              setState(() {
                                _customerSearchController.text = v;
                                // Clear selection if user edits away from match.
                                if (_customerId != null) {
                                  final selected = customers
                                      .where((c) => c.id == _customerId)
                                      .firstOrNull;
                                  if (selected == null ||
                                      selected.shopName.toLowerCase() !=
                                          v.trim().toLowerCase()) {
                                    _customerId = null;
                                  }
                                }
                              });
                            },
                            onSubmitted: (_) => onFieldSubmitted(),
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(BsRadii.md),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 240),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final c = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  title: Text(c.shopName),
                                  subtitle: Text(
                                    c.phone ?? c.contactName ?? '',
                                  ),
                                  onTap: () => onSelected(c),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (_status == BillStatus.partial) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: l10n.amountPaid),
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_status != BillStatus.due && !_walkIn ||
                  _status == BillStatus.partial) ...[
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
              ],
              const SizedBox(height: 24),
              FilledButton(onPressed: _submit, child: Text(l10n.saveBill)),
            ],
          ),
        ),
      ),
    );
  }
}
