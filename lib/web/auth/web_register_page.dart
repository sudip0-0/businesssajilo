import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_errors.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

class WebRegisterPage extends ConsumerStatefulWidget {
  const WebRegisterPage({super.key});

  @override
  ConsumerState<WebRegisterPage> createState() => _WebRegisterPageState();
}

class _WebRegisterPageState extends ConsumerState<WebRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessNameNpController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _loading = false;
  final bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _businessNameController.dispose();
    _businessNameNpController.dispose();
    _phoneController.dispose();
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
      await ref.read(authProvider.notifier).registerBusiness(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _displayNameController.text,
            businessName: _businessNameController.text,
            businessNameNp: _businessNameNpController.text.isEmpty
                ? null
                : _businessNameNpController.text,
            phone: _phoneController.text.isEmpty ? null : _phoneController.text,
            address:
                _addressController.text.isEmpty ? null : _addressController.text,
          );
    } catch (e) {
      setState(() => _error = localizeAuthError(e, AppLocalizations.of(context)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              color: BsColors.primary,
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsRegular.buildings,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    l10n.registerBusiness,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.tagline,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                                value: 'en', label: Text(l10n.english)),
                            ButtonSegment(
                                value: 'ne', label: Text(l10n.nepali)),
                          ],
                          selected: {locale.languageCode},
                          onSelectionChanged: (s) => ref
                              .read(localeProvider.notifier)
                              .setLocale(Locale(s.first)),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _businessNameController,
                          decoration:
                              InputDecoration(labelText: l10n.businessName),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? l10n.fieldRequired
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _businessNameNpController,
                          decoration:
                              InputDecoration(labelText: l10n.businessNameNp),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _displayNameController,
                          decoration:
                              InputDecoration(labelText: l10n.displayName),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? l10n.fieldRequired
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: l10n.email),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.fieldRequired;
                            }
                            if (!emailRegex.hasMatch(v.trim())) {
                              return l10n.invalidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(labelText: l10n.password),
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) return l10n.fieldRequired;
                            if (v.length < 6) return l10n.weakPassword;
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration:
                              InputDecoration(labelText: l10n.phoneNumber),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(labelText: l10n.address),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: const TextStyle(color: BsColors.danger)),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(l10n.createAccount),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(l10n.hasAccount),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: Text(l10n.signIn),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
