import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/submit_action.dart';
import '../../domain/enums.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../auth/change_password_screen.dart';
import '../auth/providers/auth_provider.dart';

/// Opens the change-password sheet for the signed-in member.
Future<void> showChangePasswordSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  await showAdaptiveSheet<void>(
    context: context,
    title: l10n.changePassword,
    child: Builder(
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ChangePasswordForm(
          onChanged: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    ),
  );
}

/// Result of the delete-confirm dialog.
typedef _DeleteConfirmResult = ({bool confirmed, String? password});

/// Confirmation + deletion flow.
///
/// Customers/staff delete their own login (anonymized; business records
/// stay). Owners delete the entire business, guarded by type-to-confirm
/// plus password re-authentication.
Future<void> confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref, {
  required bool deleteBusiness,
}) async {
  final l10n = AppLocalizations.of(context);
  const confirmWord = 'DELETE';

  final result = await showDialog<_DeleteConfirmResult>(
    context: context,
    builder: (dialogContext) => _DeleteConfirmDialog(
      title: deleteBusiness ? l10n.deleteBusiness : l10n.deleteAccount,
      warning: deleteBusiness
          ? l10n.deleteBusinessWarning
          : l10n.deleteAccountWarning,
      // Business deletion is the most destructive action in the app.
      confirmWord: deleteBusiness ? confirmWord : null,
      requirePassword: deleteBusiness,
    ),
  );
  if (result == null || !result.confirmed || !context.mounted) return;

  await runSubmitAction(
    context,
    action: () async {
      await ref
          .read(authProvider.notifier)
          .deleteAccount(
            deleteBusiness: deleteBusiness,
            password: result.password,
          );
    },
    successMessage: l10n.accountDeleted,
  );
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({
    required this.title,
    required this.warning,
    this.confirmWord,
    this.requirePassword = false,
  });

  final String title;
  final String warning;
  final String? confirmWord;
  final bool requirePassword;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  final _controller = TextEditingController();
  final _passwordController = TextEditingController();
  bool _matches = false;
  bool _passwordOk = false;

  @override
  void initState() {
    super.initState();
    _matches = widget.confirmWord == null;
    _passwordOk = !widget.requirePassword;
    _controller.addListener(_recompute);
    _passwordController.addListener(_recompute);
  }

  void _recompute() {
    final matches =
        widget.confirmWord == null ||
        _controller.text.trim() == widget.confirmWord;
    final passwordOk =
        !widget.requirePassword || _passwordController.text.isNotEmpty;
    if (matches != _matches || passwordOk != _passwordOk) {
      setState(() {
        _matches = matches;
        _passwordOk = passwordOk;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canConfirm = _matches && _passwordOk;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.warning),
          if (widget.confirmWord != null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: l10n.typeToConfirm(widget.confirmWord!),
              ),
            ),
          ],
          if (widget.requirePassword) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: l10n.confirmPasswordToDelete,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, (confirmed: false, password: null)),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: BsColors.danger),
          onPressed: canConfirm
              ? () => Navigator.pop(context, (
                  confirmed: true,
                  password: widget.requirePassword
                      ? _passwordController.text
                      : null,
                ))
              : null,
          child: Text(widget.title),
        ),
      ],
    );
  }
}

/// Settings tiles for the account: change password + delete account/business.
class AccountSettingsTiles extends ConsumerWidget {
  const AccountSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(authProvider).value?.member?.role;
    final isOwner = role == Role.owner;

    return Column(
      children: [
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.changePassword),
          onTap: () => showChangePasswordSheet(context),
        ),
        ListTile(
          leading: const Icon(
            Icons.delete_forever_outlined,
            color: BsColors.danger,
          ),
          title: Text(
            isOwner ? l10n.deleteBusiness : l10n.deleteAccount,
            style: const TextStyle(color: BsColors.danger),
          ),
          onTap: () =>
              confirmAndDeleteAccount(context, ref, deleteBusiness: isOwner),
        ),
      ],
    );
  }
}

/// App-bar popup for shells without a settings tab (customer/sales/warehouse):
/// change password and delete account.
class AccountAction extends ConsumerWidget {
  const AccountAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.account,
      icon: const Icon(Icons.person_outline),
      onSelected: (value) {
        switch (value) {
          case 'change-password':
            showChangePasswordSheet(context);
          case 'delete-account':
            confirmAndDeleteAccount(context, ref, deleteBusiness: false);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'change-password',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.changePassword),
          ),
        ),
        PopupMenuItem(
          value: 'delete-account',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: BsColors.danger,
            ),
            title: Text(
              l10n.deleteAccount,
              style: const TextStyle(color: BsColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
