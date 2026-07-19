import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/locale_toggle.dart';
import '../../core/utils/auth_errors.dart';
import '../../core/utils/login_identifier.dart';
import '../../features/auth/forgot_password_sheet.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../theme/web_palette.dart';
import '../theme/web_theme.dart';
import '../theme/web_typography.dart';
import 'web_auth_brand_panel.dart';

class WebLoginPage extends ConsumerStatefulWidget {
  const WebLoginPage({super.key});

  @override
  ConsumerState<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends ConsumerState<WebLoginPage> {
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
    final compact = MediaQuery.sizeOf(context).width < 900;

    ref.listen(authProvider, (_, next) {
      final error = next.error;
      if (error != null && mounted) {
        setState(() => _error = localizeAuthError(error, l10n));
      }
    });

    return Scaffold(
      backgroundColor: WebPalette.paper,
      body: compact
          ? _buildForm(context, l10n, showBranding: true)
          : Row(
              children: [
                Expanded(
                  flex: 11,
                  child: WebAuthBrandPanel(
                    headline: l10n.appTitle,
                    subhead: l10n.tagline,
                  ),
                ),
                Expanded(flex: 9, child: _buildForm(context, l10n)),
              ],
            ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n, {
    bool showBranding = false,
  }) {
    return ColoredBox(
      color: WebPalette.paper,
      child: Theme(
        data: WebTheme.light(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showBranding) ...[
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: WebPalette.navyWash,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: WebPalette.navy.withValues(alpha: 0.14),
                              ),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.storefront,
                              size: 21,
                              color: WebPalette.navy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.appTitle,
                            style: WebTypography.serif(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              color: WebPalette.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                    ],
                    Text(
                          l10n.signIn,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(color: WebPalette.ink),
                        )
                        .animate()
                        .fadeIn(duration: 380.ms)
                        .slideY(begin: 0.06, end: 0, duration: 380.ms),
                    const SizedBox(height: 10),
                    Text(
                      l10n.tagline,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: WebPalette.inkSoft),
                    ).animate().fadeIn(duration: 380.ms, delay: 80.ms),
                    const SizedBox(height: 28),
                    const LocaleToggle(fullWidth: true),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: WebPalette.ink),
                      decoration: InputDecoration(labelText: l10n.emailOrPhone),
                      keyboardType: TextInputType.emailAddress,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: WebPalette.ink),
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
                      validator: (v) =>
                          v == null || v.isEmpty ? l10n.fieldRequired : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          final identifier = _emailController.text.trim();
                          final isPhone =
                              identifier.isNotEmpty &&
                              !identifier.contains('@');
                          if (isPhone) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.forgotPasswordPhoneHint),
                              ),
                            );
                            return;
                          }
                          showAdaptiveSheet<void>(
                            context: context,
                            title: l10n.resetPassword,
                            child: ForgotPasswordSheet(
                              initialEmail: identifier.isEmpty
                                  ? null
                                  : identifier,
                            ),
                          );
                        },
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: WebPalette.dangerWash,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: WebPalette.danger.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.warningCircle,
                              size: 18,
                              color: WebPalette.danger,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: WebPalette.danger),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 250.ms).shakeX(hz: 2),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.signIn),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.noAccount,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: WebPalette.inkSoft),
                        ),
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
