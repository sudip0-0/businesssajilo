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
      await ref.read(authProvider.notifier).signIn(
            _emailController.text,
            _passwordController.text,
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
    final compact = MediaQuery.sizeOf(context).width < 768;

    ref.listen(authProvider, (_, next) {
      final error = next.error;
      if (error != null && mounted) {
        setState(() => _error = localizeAuthError(error, l10n));
      }
    });

    return Scaffold(
      backgroundColor: BsColors.background,
      body: compact
          ? _buildForm(context, l10n, locale, showBranding: true)
          : Row(
              children: [
                Expanded(flex: 5, child: _buildBrandPanel(context, l10n)),
                Expanded(flex: 4, child: _buildForm(context, l10n, locale)),
              ],
            ),
    );
  }

  Widget _buildBrandPanel(BuildContext context, AppLocalizations l10n) {
    return Container(
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
            child: Icon(PhosphorIconsRegular.storefront, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tagline,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 40),
          _FeatureRow(
            icon: PhosphorIconsRegular.receipt,
            text: l10n.billing,
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: PhosphorIconsRegular.package,
            text: l10n.inventory,
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: PhosphorIconsRegular.chartBar,
            text: l10n.reports,
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    Locale locale, {
    bool showBranding = false,
  }) {
    return ColoredBox(
      color: Colors.white,
      child: Theme(
        data: WebTheme.light(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showBranding) ...[
                      Icon(PhosphorIconsRegular.storefront,
                          size: 40, color: BsColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: BsColors.primary,
                            ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    Text(
                      l10n.signIn,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: BsColors.textCharcoal,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: BsColors.outline,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SegmentedButton<String>(
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
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: BsColors.text),
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? PhosphorIconsRegular.eye
                              : PhosphorIconsRegular.eyeSlash),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) =>
                          v == null || v.isEmpty ? l10n.fieldRequired : null,
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
                          : Text(l10n.signIn),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.noAccount,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: BsColors.outline,
                              ),
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
        ),
      ],
    );
  }
}
