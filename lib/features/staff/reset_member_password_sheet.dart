import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/ui/inline_form_action.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/members_repository.dart';
import '../../core/ui/adaptive_sheet.dart';

/// Owner sets a temporary password for a staff member or customer.
/// The member must choose a new password on next login.
class ResetMemberPasswordSheet extends ConsumerStatefulWidget {
  const ResetMemberPasswordSheet({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  final String memberId;
  final String memberName;

  @override
  ConsumerState<ResetMemberPasswordSheet> createState() =>
      _ResetMemberPasswordSheetState();
}

class _ResetMemberPasswordSheetState
    extends ConsumerState<ResetMemberPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    await runInlineFormAction(
      action: () async {
        await ref.read(membersRepositoryProvider).resetMemberPassword(
          memberId: widget.memberId,
          newPassword: _passwordController.text,
        );
        if (mounted) Navigator.pop(context, true);
      },
      onState: ({required loading, error}) => setState(() {
        _loading = loading;
        _error = error;
      }),
      mounted: () => mounted,
      l10n: l10n,
      mapError: (e, l) => AppFailure.from(e).message(l),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.resetPasswordFor(widget.memberName),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.temporaryPasswordHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: l10n.temporaryPassword,
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
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.fieldRequired;
                if (v.length < 8) return l10n.passwordTooShort;
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
                  : Text(l10n.resetPassword),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the reset sheet and shows a confirmation snackbar on success.
Future<void> showResetMemberPasswordSheet(
  BuildContext context, {
  required String memberId,
  required String memberName,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final done = await showAdaptiveSheet<bool>(
    context: context,
    title: l10n.resetPassword,
    child: ResetMemberPasswordSheet(memberId: memberId, memberName: memberName),
  );
  if (done == true) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.passwordResetDone)));
  }
}
