import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/customers_repository.dart';
import '../../../features/auth/login_screen.dart' show emailRegex;
import '../../../features/customers/providers.dart';
import '../../ui/web_form_card.dart';
import '../web_page_scaffold.dart';

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

class WebCustomerFormPage extends ConsumerStatefulWidget {
  const WebCustomerFormPage({super.key});

  @override
  ConsumerState<WebCustomerFormPage> createState() =>
      _WebCustomerFormPageState();
}

class _WebCustomerFormPageState extends ConsumerState<WebCustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _panController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');
  String? _city;
  bool _loading = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
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
    setState(() => _loading = true);
    try {
      await ref.read(customersRepositoryProvider).createWithCredentials(
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim().isEmpty
                ? _contactNameController.text.trim()
                : _displayNameController.text.trim(),
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
      ref.invalidate(customerListProvider);
      ref.invalidate(totalDuesProvider);
      if (mounted) context.go('/owner/customers');
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

    return WebPageScaffold(
      title: l10n.addNewCustomer,
      subtitle: l10n.addCustomerSubtitle,
      breadcrumbs: [l10n.customers, l10n.addNewCustomer],
      actions: [
        OutlinedButton(
          onPressed: () => context.go('/owner/customers'),
          child: Text(l10n.cancel),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(PhosphorIconsRegular.floppyDisk, size: 18),
          label: Text(l10n.saveCustomer),
        ),
      ],
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebFormCard(
                title: l10n.customerIdentity,
                subtitle: l10n.customerIdentityHint,
                icon: PhosphorIconsRegular.userPlus,
                children: [
                  WebFormRow(
                    children: [
                      TextFormField(
                        controller: _shopNameController,
                        decoration: InputDecoration(
                          labelText: '${l10n.businessName} *',
                          hintText: 'e.g., Himalayan Traders',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? l10n.fieldRequired
                            : null,
                      ),
                      TextFormField(
                        controller: _contactNameController,
                        decoration: InputDecoration(
                          labelText: '${l10n.ownerName} *',
                          hintText: 'e.g., Rajesh Hamal',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? l10n.fieldRequired
                            : null,
                      ),
                    ],
                  ),
                  const WebFormSectionLabel('Contact & Location'),
                  WebFormRow(
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: '${l10n.phoneNumber} *',
                          hintText: '98XXXXXXXX',
                          prefixText: '+977 ',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? l10n.fieldRequired
                            : null,
                      ),
                      // Email optional: phone doubles as the login identifier.
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l10n.emailAddress,
                          hintText: 'customer@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!emailRegex.hasMatch(v.trim())) {
                            return l10n.invalidEmail;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  WebFormRow(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _city,
                        decoration: InputDecoration(
                          labelText: '${l10n.city} *',
                          hintText: l10n.selectCity,
                        ),
                        items: _nepalCities
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _city = v),
                        validator: (v) =>
                            v == null || v.isEmpty ? l10n.fieldRequired : null,
                      ),
                      TextFormField(
                        controller: _districtController,
                        decoration: InputDecoration(
                          labelText: '${l10n.district} *',
                          hintText: 'e.g., Kathmandu District',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? l10n.fieldRequired
                            : null,
                      ),
                    ],
                  ),
                  const WebFormSectionLabel('Financial Information'),
                  WebFormRow(
                    children: [
                      TextFormField(
                        controller: _panController,
                        decoration: InputDecoration(
                          labelText: l10n.panVatNumber,
                          hintText: '9-digit PAN or VAT',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: _creditLimitController,
                        decoration: InputDecoration(
                          labelText: l10n.openingBalance,
                          prefixText: 'Rs. ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  const WebFormSectionLabel('Portal Access'),
                  WebFormRow(
                    children: [
                      TextFormField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: l10n.displayName,
                        ),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: '${l10n.password} *',
                        ),
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.fieldRequired;
                          if (v.length < 8) return l10n.passwordTooShort;
                          return null;
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.portalAccessHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BsColors.outline,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 768;
                  final tips = [
                    WebInfoTipCard(
                      message: l10n.verificationTip,
                      color: BsColors.secondary,
                      icon: PhosphorIconsRegular.shieldCheck,
                    ),
                    WebInfoTipCard(
                      message: l10n.creditPolicyTip,
                      color: BsColors.accent,
                      icon: PhosphorIconsRegular.wallet,
                    ),
                    WebInfoTipCard(
                      message: l10n.privacyTip,
                      color: BsColors.outline,
                      icon: PhosphorIconsRegular.lock,
                    ),
                  ];
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < tips.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: tips[i]),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < tips.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        tips[i],
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
