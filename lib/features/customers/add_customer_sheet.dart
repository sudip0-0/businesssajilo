import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_form_section.dart';
import '../../core/ui/bs_success_button.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/customers_repository.dart';
import '../auth/login_screen.dart' show emailRegex;

const _nepalCities = [
  'Kathmandu',
  'Lalitpur',
  'Bhaktapur',
  'Pokhara',
  'Biratnagar',
  'Birgunj',
  'Dharan',
  'Butwal',
  'Hetauda',
  'Nepalgunj',
];

class AddCustomerSheet extends ConsumerStatefulWidget {
  const AddCustomerSheet({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _panController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');
  String? _city;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _contactNameController.dispose();
    _districtController.dispose();
    _panController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  String? _buildAddress() {
    final parts = <String>[
      if (_city != null) _city!,
      if (_districtController.text.trim().isNotEmpty)
        _districtController.text.trim(),
      if (_panController.text.trim().isNotEmpty)
        'PAN: ${_panController.text.trim()}',
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(customersRepositoryProvider).createWithCredentials(
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
            shopName: _shopNameController.text.trim(),
            contactName: _contactNameController.text.trim().isEmpty
                ? null
                : _contactNameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : '+977${_phoneController.text.trim()}',
            address: _buildAddress(),
            openingBalance:
                parseNpr(_creditLimitController.text)?.value ?? 0,
          );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).actionFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _formBody(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BsFormCard(
            margin: EdgeInsets.zero,
            title: l10n.customerIdentity,
            subtitle: l10n.customerIdentityHint,
            icon: Icons.person_add_outlined,
            children: [
              TextFormField(
                controller: _shopNameController,
                decoration: InputDecoration(
                  labelText: '${l10n.businessName} *',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactNameController,
                decoration: InputDecoration(
                  labelText: '${l10n.ownerName} *',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const BsFormSectionLabel('Contact & Location'),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '${l10n.phoneNumber} *',
                  prefixText: '+977 ',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _city,
                decoration: InputDecoration(labelText: '${l10n.city} *'),
                items: _nepalCities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _city = v),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: '${l10n.district} *',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const BsFormSectionLabel('Financial Information'),
              TextFormField(
                controller: _creditLimitController,
                decoration: InputDecoration(
                  labelText: l10n.openingBalance,
                  prefixText: 'Rs. ',
                ),
                keyboardType: TextInputType.number,
              ),
              const BsFormSectionLabel('Portal Access'),
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: l10n.displayName),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              // Email optional: phone doubles as the login identifier.
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: l10n.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!emailRegex.hasMatch(v.trim())) return l10n.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: '${l10n.password} *'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  if (v.length < 8) return l10n.passwordTooShort;
                  return null;
                },
              ),
              Text(
                l10n.portalAccessHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BsColors.outline,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BsInfoTipCard(
            message: l10n.verificationTip,
            color: BsColors.secondary,
            icon: Icons.verified_user_outlined,
          ),
          BsInfoTipCard(
            message: l10n.creditPolicyTip,
            color: BsColors.accent,
            icon: Icons.account_balance_wallet_outlined,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: BsColors.danger)),
          ],
          const SizedBox(height: 16),
          BsSuccessButton(
            onPressed: _loading ? null : _submit,
            label: l10n.saveCustomer,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    if (widget.embedded) {
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
        child: _formBody(l10n),
      );
    }

    return Material(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addNewCustomer,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.addCustomerSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BsColors.outline,
                    ),
              ),
              const SizedBox(height: 16),
              _formBody(l10n),
            ],
          ),
        ),
      ),
    );
  }
}
