import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/export/clipboard_image.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_snackbar.dart';

/// Full-screen preview of a statement PNG.
Future<void> showStatementImagePreview(
  BuildContext context, {
  required Uint8List pngBytes,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => StatementImagePreview(pngBytes: pngBytes),
  );
}

class StatementImagePreview extends StatelessWidget {
  const StatementImagePreview({super.key, required this.pngBytes});

  final Uint8List pngBytes;

  Future<void> _copy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await copyPngToClipboard(Future.value(pngBytes));
      if (context.mounted) {
        showBsSnackBar(context, message: l10n.statementImageCopied);
      }
    } catch (e) {
      if (context.mounted) {
        showBsSnackBar(
          context,
          message: AppFailure.from(e).message(l10n),
          backgroundColor: BsColors.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.previewStatement),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.close,
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.copyAsImage),
            ),
          ],
        ),
        body: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Image.memory(
                pngBytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
