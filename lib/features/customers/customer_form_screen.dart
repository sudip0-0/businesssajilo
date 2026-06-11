import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/customers_repository.dart';
import 'providers.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(customersRepositoryProvider).update(
            id: widget.customerId,
            shopName: _shopNameController.text.trim(),
            contactName: _contactNameController.text.trim().isEmpty
                ? null
                : _contactNameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            openingBalance:
                parseNpr(_openingBalanceController.text)?.value ?? 0,
          );
      if (mounted) Navigator.pop(context, true);
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
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editCustomer)),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (customer) {
          if (!_initialized) {
            _shopNameController.text = customer.shopName;
            _contactNameController.text = customer.contactName ?? '';
            _phoneController.text = customer.phone ?? '';
            _addressController.text = customer.address ?? '';
            _openingBalanceController.text = formatNpr(
              Paisa(customer.openingBalance),
              showSymbol: false,
              showPaisa: false,
            );
            _initialized = true;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _shopNameController,
                    decoration: InputDecoration(labelText: l10n.shopName),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? l10n.fieldRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactNameController,
                    decoration: InputDecoration(labelText: l10n.contactName),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: l10n.phoneNumber),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: l10n.address),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _openingBalanceController,
                    decoration: InputDecoration(labelText: l10n.openingBalance),
                    keyboardType: TextInputType.number,
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
          );
        },
      ),
    );
  }
}
