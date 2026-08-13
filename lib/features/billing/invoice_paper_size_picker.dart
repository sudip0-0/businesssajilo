import 'package:flutter/material.dart';

import '../../core/invoicing/invoice_paper_size.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/adaptive_sheet.dart';

/// Asks the user to pick A4 or A5 before printing / downloading / copying.
///
/// When [onSelected] is set, it runs before the sheet closes (used to start
/// clipboard writes inside the tap gesture). The sheet stays open until it
/// completes, then pops with the chosen size.
Future<InvoicePaperSize?> showInvoicePaperSizePicker(
  BuildContext context, {
  required String title,
  Future<void> Function(InvoicePaperSize size)? onSelected,
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
      a5Label: l10n.paperSizeA5,
      a5Desc: l10n.paperSizeA5Desc,
      cancelLabel: l10n.cancel,
      onSelected: onSelected,
    ),
  );
}

class _PaperSizePickerBody extends StatefulWidget {
  const _PaperSizePickerBody({
    required this.title,
    required this.chooseLabel,
    required this.a4Label,
    required this.a4Desc,
    required this.a5Label,
    required this.a5Desc,
    required this.cancelLabel,
    this.onSelected,
  });

  final String title;
  final String chooseLabel;
  final String a4Label;
  final String a4Desc;
  final String a5Label;
  final String a5Desc;
  final String cancelLabel;
  final Future<void> Function(InvoicePaperSize size)? onSelected;

  @override
  State<_PaperSizePickerBody> createState() => _PaperSizePickerBodyState();
}

class _PaperSizePickerBodyState extends State<_PaperSizePickerBody> {
  InvoicePaperSize? _busySize;

  bool get _busy => _busySize != null;

  Future<void> _choose(InvoicePaperSize size) async {
    if (_busy) return;
    final onSelected = widget.onSelected;
    if (onSelected == null) {
      Navigator.of(context).pop(size);
      return;
    }
    setState(() => _busySize = size);
    try {
      await onSelected(size);
      if (mounted) Navigator.of(context).pop(size);
    } catch (_) {
      if (mounted) setState(() => _busySize = null);
    }
  }

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
              widget.chooseLabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _SizeOption(
              label: widget.a4Label,
              description: widget.a4Desc,
              icon: Icons.description_outlined,
              busy: _busySize == InvoicePaperSize.a4,
              enabled: !_busy,
              onTap: () => _choose(InvoicePaperSize.a4),
            ),
            const SizedBox(height: 10),
            _SizeOption(
              label: widget.a5Label,
              description: widget.a5Desc,
              icon: Icons.note_outlined,
              busy: _busySize == InvoicePaperSize.a5,
              enabled: !_busy,
              onTap: () => _choose(InvoicePaperSize.a5),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(widget.cancelLabel),
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
    this.busy = false,
    this.enabled = true,
  });

  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool busy;
  final bool enabled;

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
        onTap: enabled ? onTap : null,
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
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
