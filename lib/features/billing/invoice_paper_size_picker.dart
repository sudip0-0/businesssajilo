import 'package:flutter/material.dart';

import '../../core/invoicing/invoice_paper_size.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/adaptive_sheet.dart';

/// Asks the user to pick A4 or A2 before printing / downloading a bill PDF.
Future<InvoicePaperSize?> showInvoicePaperSizePicker(
  BuildContext context, {
  required String title,
}) {
  final l10n = AppLocalizations.of(context);
  return showAdaptiveSheet<InvoicePaperSize>(
    context: context,
    title: title,
    child: _PaperSizePickerBody(
      title: title,
      chooseLabel: l10n.choosePaperSize,
      a4Label: l10n.paperSizeA4,
      a4Desc: l10n.paperSizeA4Desc,
      a2Label: l10n.paperSizeA2,
      a2Desc: l10n.paperSizeA2Desc,
      cancelLabel: l10n.cancel,
    ),
  );
}

class _PaperSizePickerBody extends StatelessWidget {
  const _PaperSizePickerBody({
    required this.title,
    required this.chooseLabel,
    required this.a4Label,
    required this.a4Desc,
    required this.a2Label,
    required this.a2Desc,
    required this.cancelLabel,
  });

  final String title;
  final String chooseLabel;
  final String a4Label;
  final String a4Desc;
  final String a2Label;
  final String a2Desc;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              chooseLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _SizeOption(
              label: a4Label,
              description: a4Desc,
              icon: Icons.description_outlined,
              onTap: () => Navigator.of(context).pop(InvoicePaperSize.a4),
            ),
            const SizedBox(height: 10),
            _SizeOption(
              label: a2Label,
              description: a2Desc,
              icon: Icons.crop_landscape_outlined,
              onTap: () => Navigator.of(context).pop(InvoicePaperSize.a2),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeOption extends StatelessWidget {
  const _SizeOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BsRadii.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(BsRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
