import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/invoicing/statement_export_service.dart';
import '../../core/l10n/app_localizations.dart';

/// Full-screen preview of a statement PNG with a share action.
Future<void> showStatementImagePreview(
  BuildContext context, {
  required Uint8List pngBytes,
  required String fileName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) =>
        StatementImagePreview(pngBytes: pngBytes, fileName: fileName),
  );
}

class StatementImagePreview extends ConsumerWidget {
  const StatementImagePreview({
    super.key,
    required this.pngBytes,
    required this.fileName,
  });

  final Uint8List pngBytes;
  final String fileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.shareStatement),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.close,
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await ref
                    .read(statementExportServiceProvider)
                    .sharePngBytes(pngBytes, fileName: fileName);
              },
              icon: const Icon(Icons.share_outlined),
              label: Text(l10n.shareAsImage),
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
