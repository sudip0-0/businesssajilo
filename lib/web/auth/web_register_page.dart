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
import '../theme/web_theme.dart';

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
  bool _obscurePassword = true;
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
      await ref
          .read(authProvider.notifier)
          .registerBusiness(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _displayNameController.text,
            businessName: _businessNameController.text,
            businessNameNp: _businessNameNpController.text.isEmpty
                ? null
                : _businessNameNpController.text,
            phone: _phoneController.text.isEmpty ? null : _phoneController.text,
            address: _addressController.text.isEmpty
                ? null
                : _addressController.text,
          );
    } catch (e) {
      setState(
        () => _error = localizeAuthError(e, AppLocalizations.of(context)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    final compact = MediaQuery.sizeOf(context).width < 768;

    return Scaffold(
      backgroundColor: BsColors.background,
      body: compact
          ? _buildFormOnly(context, l10n, locale)
          : Row(
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
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(BsRadii.lg),
                          ),
                          child: Icon(
                            PhosphorIconsRegular.buildings,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.registerBusiness,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.tagline,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(flex: 5, child: _buildFormOnly(context, l10n, locale)),
              ],
            ),
    );
  }

  Widget _buildFormOnly(
    BuildContext context,
    AppLocalizations l10n,
    Locale locale,
  ) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return ColoredBox(
      color: Colors.white,
      child: Theme(
        data: WebTheme.light(),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(48, 48, 48, 48 + bottomInset),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.registerBusiness,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: BsColors.textCharcoal),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: 'en', label: Text(l10n.english)),
                        ButtonSegment(value: 'ne', label: Text(l10n.nepali)),
                      ],
                      selected: {locale.languageCode},
                      onSelectionChanged: (s) => ref
                          .read(localeProvider.notifier)
                          .setLocale(Locale(s.first)),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _businessNameController,
                      style: const TextStyle(color: BsColors.text),
                      decoration: InputDecoration(labelText: l10n.businessName),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l10n.fieldRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _businessNameNpController,
                      style: const TextStyle(color: BsColors.text),
                      decoration: InputDecoration(
                        labelText: l10n.businessNameNp,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _displayNameController,
                      style: const TextStyle(color: BsColors.text),
                      decoration: InputDecoration(labelText: l10n.displayName),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l10n.fieldRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: BsColors.text),
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
                      style: const TextStyle(color: BsColors.text),
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? PhosphorIconsRegular.eye
                                : PhosphorIconsRegular.eyeSlash,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.fieldRequired;
                        if (v.length < 8) return l10n.passwordTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: BsColors.text),
                      decoration: InputDecoration(labelText: l10n.phoneNumber),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(color: BsColors.text),
                      decoration: InputDecoration(labelText: l10n.address),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BsColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(BsRadii.md),
                          border: Border.all(
                            color: BsColors.danger.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: BsColors.danger),
                        ),
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
                          : Text(l10n.createAccount),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.hasAccount,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: BsColors.outline),
                        ),
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
    );
  }
}
