import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/utils/money.dart';
import '../../core/utils/payment_method_label.dart';
import '../../domain/enums.dart';
import '../../domain/models/customer.dart';
import '../auth/providers/auth_provider.dart';
import '../customers/providers.dart';
import 'validate_bill_payment.dart';

export 'bill_payment_result.dart';

class BillPaymentSheet extends ConsumerStatefulWidget {
  const BillPaymentSheet({
    super.key,
    required this.grandTotal,
    this.initialCustomerId,
    this.initialCustomerName,
    this.initialGuestName,
  });

  final int grandTotal;
  final String? initialCustomerId;

  /// Display name for [initialCustomerId] (e.g. from order prefill).
  /// When omitted, the sheet loads the customer by id.
  final String? initialCustomerName;
  final String? initialGuestName;

  @override
  ConsumerState<BillPaymentSheet> createState() => _BillPaymentSheetState();
}

class _BillPaymentSheetState extends ConsumerState<BillPaymentSheet> {
  BillStatus _status = BillStatus.paid;
  bool _walkIn = false;
  String? _customerId;
  String? _selectedShopName;
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _customerSearchController = TextEditingController();
  final _guestNameController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    _walkIn = widget.initialCustomerId == null;
    // Warehouse (no payment recording) defaults customer bills to due.
    _status = _walkIn ? BillStatus.paid : BillStatus.due;
    final guest = widget.initialGuestName?.trim();
    if (_walkIn && guest != null && guest.isNotEmpty) {
      _guestNameController.text = guest;
    }
    final name = widget.initialCustomerName?.trim();
    if (_customerId != null && name != null && name.isNotEmpty) {
      _selectedShopName = name;
      _customerSearchController.text = name;
    }
    _amountController.text = formatNpr(
      Paisa(widget.grandTotal),
      showSymbol: false,
      showPaisa: false,
    );
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _customerId = customer.id;
      _selectedShopName = customer.shopName;
      _customerSearchController.text = customer.shopName;
    });
  }

  void _applyCustomerLabel(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_selectedShopName == trimmed &&
        _customerSearchController.text == trimmed) {
      return;
    }
    setState(() {
      _selectedShopName = trimmed;
      _customerSearchController.text = trimmed;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _customerSearchController.dispose();
    _guestNameController.dispose();
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
        guestName: _guestNameController.text,
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
    showBsSnackBar(
      context,
      message: message,
      backgroundColor: BsColors.danger,
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
    // Search list by typed query, but keep the selected name visible even when
    // that customer is outside the first page of an empty query.
    final listQuery =
        _customerId != null &&
            _selectedShopName != null &&
            _customerSearchController.text.trim().toLowerCase() ==
                _selectedShopName!.toLowerCase()
        ? ''
        : _customerSearchController.text.trim();
    final customersAsync = ref.watch(customerListProvider(listQuery));

    final initialId = widget.initialCustomerId;
    if (!_walkIn &&
        initialId != null &&
        _customerId == initialId &&
        _selectedShopName == null) {
      ref.listen(customerDetailProvider(initialId), (prev, next) {
        final customer = next.value;
        if (customer != null) _applyCustomerLabel(customer.shopName);
      });
      final cached = ref.watch(customerDetailProvider(initialId)).value;
      if (cached != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applyCustomerLabel(cached.shopName);
        });
      }
    }

    final canRecordPayments =
        ref.watch(authProvider).value?.member?.role.canRecordPayments ??
        false;

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
                  if (canRecordPayments || _walkIn)
                    ButtonSegment(
                      value: BillStatus.paid,
                      label: Text(l10n.paid),
                    ),
                  if (canRecordPayments)
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
                    _selectedShopName = null;
                    _customerSearchController.clear();
                    if (!canRecordPayments) _status = BillStatus.paid;
                  } else {
                    _guestNameController.clear();
                    if (!canRecordPayments) _status = BillStatus.due;
                    final initial = widget.initialCustomerId;
                    final name = widget.initialCustomerName?.trim();
                    if (initial != null) {
                      _customerId = initial;
                      if (name != null && name.isNotEmpty) {
                        _selectedShopName = name;
                        _customerSearchController.text = name;
                      }
                    }
                  }
                }),
              ),
              if (_walkIn) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _guestNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.customerName,
                    hintText: l10n.walkInNameHint,
                  ),
                ),
              ],
              if (!_walkIn)
                customersAsync.when(
                  loading: () => _selectedShopName != null
                      ? TextField(
                          controller: _customerSearchController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: l10n.selectCustomer,
                            prefixIcon: const Icon(Icons.search),
                          ),
                        )
                      : const LinearProgressIndicator(),
                  error: (e, _) => Text(l10n.loadingFailed),
                  data: (customers) => Autocomplete<Customer>(
                    key: ValueKey(
                      'bill-customer-${_customerId ?? 'none'}-'
                      '${_selectedShopName ?? ''}',
                    ),
                    initialValue: TextEditingValue(
                      text: _customerSearchController.text,
                    ),
                    displayStringForOption: (c) => c.shopName,
                    optionsBuilder: (textEditingValue) {
                      return _filterCustomers(customers, textEditingValue.text);
                    },
                    onSelected: _selectCustomer,
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
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
                                if (_customerId != null &&
                                    (_selectedShopName ?? '').toLowerCase() !=
                                        v.trim().toLowerCase()) {
                                  _customerId = null;
                                  _selectedShopName = null;
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
