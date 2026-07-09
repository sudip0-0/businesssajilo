import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/locale_toggle.dart';
import '../../core/utils/auth_errors.dart';
import '../../core/utils/login_identifier.dart';
import '../../core/ui/adaptive_sheet.dart';
import 'forgot_password_sheet.dart';
import 'providers/auth_provider.dart';

final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          .signIn(_emailController.text, _passwordController.text);
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
    // Surface session-restore errors (e.g. deactivated account) too.
    ref.listen(authProvider, (_, next) {
      final error = next.error;
      if (error != null && mounted) {
        setState(() => _error = localizeAuthError(error, l10n));
      }
    });
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.storefront,
                      size: 56,
                      color: BsColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: BsColors.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const LocaleToggle(fullWidth: true),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: l10n.emailOrPhone),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.fieldRequired;
                        }
                        if (!isValidLoginIdentifier(v)) {
                          return l10n.invalidEmailOrPhone;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? l10n.showPassword
                              : l10n.hidePassword,
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) =>
                          v == null || v.isEmpty ? l10n.fieldRequired : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          final identifier = _emailController.text.trim();
                          showAdaptiveSheet<void>(
                            context: context,
                            title: l10n.resetPassword,
                            child: ForgotPasswordSheet(
                              initialEmail: identifier.contains('@')
                                  ? identifier
                                  : null,
                            ),
                          );
                        },
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
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
                          : Text(l10n.signIn),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l10n.noAccount),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(l10n.signUp),
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
