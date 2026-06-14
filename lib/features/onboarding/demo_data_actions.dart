import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import 'demo_data_seeder.dart';

/// Confirms with the user, then seeds sample business data when accepted.
Future<void> confirmAndSeedDemoData({
  required BuildContext context,
  required WidgetRef ref,
  required ValueChanged<bool> onSeedingChanged,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.loadDemoData),
      content: Text(l10n.loadDemoDataConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.loadDemoData),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  onSeedingChanged(true);
  try {
    final result = await DemoDataSeeder(ref).seed();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result == DemoSeedResult.loaded
              ? l10n.demoDataLoaded
              : l10n.demoDataSkipped,
        ),
      ),
    );
  } finally {
    if (context.mounted) onSeedingChanged(false);
  }
}
