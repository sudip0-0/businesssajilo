import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/enums.dart';
import '../../web/ui/web_sheet_bridge.dart';
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

/// Confirmation + deletion flow.
///
/// Customers/staff delete their own login (anonymized; business records
/// stay). Owners delete the entire business, guarded by type-to-confirm.
Future<void> confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref, {
  required bool deleteBusiness,
}) async {
  final l10n = AppLocalizations.of(context);
  const confirmWord = 'DELETE';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _DeleteConfirmDialog(
      title: deleteBusiness ? l10n.deleteBusiness : l10n.deleteAccount,
      warning: deleteBusiness
          ? l10n.deleteBusinessWarning
          : l10n.deleteAccountWarning,
      // Business deletion is the most destructive action in the app.
      confirmWord: deleteBusiness ? confirmWord : null,
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(authProvider.notifier)
        .deleteAccount(deleteBusiness: deleteBusiness);
    messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({
    required this.title,
    required this.warning,
    this.confirmWord,
  });

  final String title;
  final String warning;
  final String? confirmWord;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _matches = widget.confirmWord == null;
    _controller.addListener(() {
      final matches = widget.confirmWord == null ||
          _controller.text.trim() == widget.confirmWord;
      if (matches != _matches) setState(() => _matches = matches);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: BsColors.danger),
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
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
          leading: const Icon(Icons.delete_forever_outlined,
              color: BsColors.danger),
          title: Text(
            isOwner ? l10n.deleteBusiness : l10n.deleteAccount,
            style: const TextStyle(color: BsColors.danger),
          ),
          onTap: () => confirmAndDeleteAccount(
            context,
            ref,
            deleteBusiness: isOwner,
          ),
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
