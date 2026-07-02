import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../shell/logout_action.dart';
import 'providers/auth_provider.dart';

/// Full-screen forced password change (owner reset the member's password).
/// The router keeps users here until [SessionState.mustChangePassword] clears.
class ForcedChangePasswordScreen extends StatelessWidget {
  const ForcedChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setNewPasswordTitle),
        automaticallyImplyLeading: false,
        actions: const [LogoutAction()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 56, color: BsColors.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.setNewPasswordHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                const ChangePasswordForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// New password + confirmation form; calls [AuthController.updateOwnPassword].
class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key, this.onChanged});

  /// Called after the password has been updated successfully.
  final VoidCallback? onChanged;

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .updateOwnPassword(_passwordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.passwordChanged)),
        );
        widget.onChanged?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: l10n.newPassword,
              suffixIcon: IconButton(
                tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.fieldRequired;
              if (v.length < 8) return l10n.passwordTooShort;
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmController,
            decoration: InputDecoration(labelText: l10n.confirmPassword),
            obscureText: _obscure,
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.fieldRequired;
              if (v != _passwordController.text) {
                return l10n.passwordsDoNotMatch;
              }
              return null;
            },
          ),
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
                : Text(l10n.changePassword),
          ),
        ],
      ),
    );
  }
}
