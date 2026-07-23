import 'package:flutter/material.dart';

import '../errors/app_failure.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Runs a form/sheet submit [action], mapping failures to a danger snackbar.
///
/// Returns `true` on success, `false` on failure (or if [context] unmounts).
/// Optionally shows [successMessage] when the action completes.
Future<bool> runSubmitAction(
  BuildContext context, {
  required Future<void> Function() action,
  String? successMessage,
}) async {
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    if (!context.mounted) return false;
    if (successMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    }
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    final failure = AppFailure.from(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure.message(l10n)),
        backgroundColor: BsColors.danger,
      ),
    );
    return false;
  }
}
