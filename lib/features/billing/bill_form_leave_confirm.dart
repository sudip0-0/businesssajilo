import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// Confirms leaving an unsaved bill form. Returns `true` if the user chose to
/// discard and leave.
Future<bool> confirmLeaveUnsavedBill(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.unsavedBillTitle),
      content: Text(l10n.unsavedBillMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.keepEditing),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.discardAndLeave),
        ),
      ],
    ),
  );
  return result == true;
}
