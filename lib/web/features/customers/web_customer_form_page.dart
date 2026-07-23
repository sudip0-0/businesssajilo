import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/submit_action.dart';
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

String _autoPassword() {
  const chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rand = Random.secure();
  return List.generate(12, (_) => chars[rand.nextInt(chars.length)]).join();
}

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
  final _openingBalanceController = TextEditingController(text: '0');
  String? _city;
  bool _loading = false;
  bool _showMore = false;
  bool _enablePortal = false;

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
    _openingBalanceController.dispose();
    super.dispose();
  }

  String? _buildAddress() {
    final parts = <String>[
      ?_city,
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
    await runSubmitAction(
      context,
      action: () async {
        final shop = _shopNameController.text.trim();
        final contact = _contactNameController.text.trim();
        final displayName = _enablePortal
            ? (_displayNameController.text.trim().isEmpty
                  ? (contact.isEmpty ? shop : contact)
                  : _displayNameController.text.trim())
            : (contact.isEmpty ? shop : contact);
        final password = _enablePortal
            ? _passwordController.text
            : _autoPassword();

        await ref
            .read(customersRepositoryProvider)
            .createWithCredentials(
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim().toLowerCase(),
              password: password,
              displayName: displayName,
              shopName: shop,
              contactName: contact.isEmpty ? null : contact,
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : '+977${_phoneController.text.trim()}',
              address: _buildAddress(),
              openingBalance:
                  parseNpr(_openingBalanceController.text)?.value ?? 0,
              portalEnabled: _enablePortal,
            );
        ref.invalidate(customerListProvider);
        ref.invalidate(totalDuesProvider);
        bumpCustomersRevision(ref);
        if (mounted) context.go('/owner/customers');
      },
    );
    if (mounted) setState(() => _loading = false);
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
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? l10n.fieldRequired
                            : null,
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: '${l10n.phoneNumber} *',
                          prefixText: '+977 ',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? l10n.fieldRequired
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _openingBalanceController,
                    decoration: InputDecoration(
                      labelText: l10n.openingBalance,
                      prefixText: 'Rs. ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => _showMore = !_showMore),
                      child: Text(
                        _showMore ? l10n.contactAndLocation : l10n.moreDetails,
                      ),
                    ),
                  ),
                  if (_showMore) ...[
                    WebFormSectionLabel(l10n.contactAndLocation),
                    TextFormField(
                      controller: _contactNameController,
                      decoration: InputDecoration(labelText: l10n.ownerName),
                    ),
                    const SizedBox(height: 16),
                    WebFormRow(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _city,
                          decoration: InputDecoration(
                            labelText: l10n.city,
                            hintText: l10n.selectCity,
                          ),
                          items: _nepalCities
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _city = v),
                        ),
                        TextFormField(
                          controller: _districtController,
                          decoration: InputDecoration(labelText: l10n.district),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _panController,
                      decoration: InputDecoration(labelText: l10n.panVatNumber),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.enablePortalAccess),
                    subtitle: Text(l10n.portalAccessHint),
                    value: _enablePortal,
                    onChanged: (v) => setState(() => _enablePortal = v),
                  ),
                  if (_enablePortal) ...[
                    WebFormSectionLabel(l10n.portalAccess),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(labelText: l10n.displayName),
                    ),
                    const SizedBox(height: 16),
                    WebFormRow(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: '${l10n.emailAddress} *',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (!_enablePortal) return null;
                            if (v == null || v.trim().isEmpty) {
                              return l10n.fieldRequired;
                            }
                            if (!emailRegex.hasMatch(v.trim())) {
                              return l10n.invalidEmail;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: '${l10n.password} *',
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (!_enablePortal) return null;
                            if (v == null || v.isEmpty) {
                              return l10n.fieldRequired;
                            }
                            if (v.length < 8) return l10n.passwordTooShort;
                            return null;
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
