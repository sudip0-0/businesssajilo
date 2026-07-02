import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/role_label.dart';
import '../../data/repositories/members_repository.dart';
import '../../domain/enums.dart';
import '../auth/login_screen.dart' show emailRegex;

class AddMemberSheet extends ConsumerStatefulWidget {
  const AddMemberSheet({super.key});

  @override
  ConsumerState<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  Role _role = Role.sales;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _addressController = TextEditingController();
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
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(membersRepositoryProvider).createMember(
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            password: _passwordController.text,
            role: _role,
            displayName: _displayNameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            shopName: _role == Role.customer
                ? _shopNameController.text.trim()
                : null,
            contactName: _role == Role.customer &&
                    _contactNameController.text.trim().isNotEmpty
                ? _contactNameController.text.trim()
                : null,
            address: _role == Role.customer &&
                    _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).actionFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addMember,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Role>(
                // ignore: deprecated_member_use
                value: _role,
                decoration: InputDecoration(labelText: l10n.staff),
                items: [Role.sales, Role.warehouse, Role.customer]
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(roleLabel(l10n, r)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? Role.sales),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: l10n.displayName),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              // Email or phone is required; phone doubles as a login
              // identifier when email is left empty.
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: l10n.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final email = v?.trim() ?? '';
                  if (email.isEmpty) {
                    return _phoneController.text.trim().isEmpty
                        ? l10n.fieldRequired
                        : null;
                  }
                  if (!emailRegex.hasMatch(email)) return l10n.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: l10n.password),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  if (v.length < 8) return l10n.passwordTooShort;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: l10n.phoneNumber),
                keyboardType: TextInputType.phone,
              ),
              if (_role == Role.customer) ...[
                const SizedBox(height: 12),
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
                  controller: _addressController,
                  decoration: InputDecoration(labelText: l10n.address),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: BsColors.danger)),
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
