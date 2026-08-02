import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Error state with plain-language message and optional retry (Design.md).
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.hasBoundedHeight && constraints.maxHeight < 220;
        final padding = compact ? 12.0 : 32.0;
        final iconSize = compact ? 36.0 : 56.0;
        final gap = compact ? 8.0 : 16.0;

        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: iconSize, color: scheme.error),
                  SizedBox(height: gap),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      message ?? l10n.somethingWentWrong,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (onRetry != null) ...[
                    SizedBox(height: gap),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.tryAgain),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
