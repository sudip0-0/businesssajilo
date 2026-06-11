import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';

class LogoutAction extends ConsumerWidget {
  const LogoutAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.logout,
      icon: const Icon(Icons.logout),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.logout),
            content: Text(l10n.logoutConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.logout),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(authProvider.notifier).signOut();
        }
      },
    );
  }
}
