import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/app_prefs.dart';

/// Short first-run walkthrough: product → customer → bill → payment.
Future<void> maybeShowFirstRunTour(BuildContext context) async {
  if (await isOnboardingTourDone()) return;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _FirstRunTourDialog(),
  );
}

class _FirstRunTourDialog extends StatefulWidget {
  const _FirstRunTourDialog();

  @override
  State<_FirstRunTourDialog> createState() => _FirstRunTourDialogState();
}

class _FirstRunTourDialogState extends State<_FirstRunTourDialog> {
  var _step = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      (l10n.tourStepProductTitle, l10n.tourStepProductBody),
      (l10n.tourStepCustomerTitle, l10n.tourStepCustomerBody),
      (l10n.tourStepBillTitle, l10n.tourStepBillBody),
      (l10n.tourStepPaymentTitle, l10n.tourStepPaymentBody),
    ];
    final last = _step == steps.length - 1;
    return AlertDialog(
      title: Text(steps[_step].$1),
      content: Text(steps[_step].$2),
      actions: [
        TextButton(
          onPressed: () async {
            await markOnboardingTourDone();
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.skip),
        ),
        FilledButton(
          onPressed: () async {
            if (last) {
              await markOnboardingTourDone();
              if (context.mounted) Navigator.pop(context);
              return;
            }
            setState(() => _step++);
          },
          child: Text(last ? l10n.done : l10n.next),
        ),
      ],
    );
  }
}
