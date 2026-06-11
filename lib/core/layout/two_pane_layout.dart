import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'adaptive_scaffold.dart';

class TwoPaneLayout extends StatelessWidget {
  const TwoPaneLayout({
    super.key,
    required this.listPane,
    required this.detailPane,
    this.listWidth = 360,
  });

  final Widget listPane;
  final Widget? detailPane;
  final double listWidth;

  @override
  Widget build(BuildContext context) {
    if (!isWideLayout(context)) {
      return listPane;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: listWidth, child: listPane),
        const VerticalDivider(width: 1),
        Expanded(child: detailPane ?? const _EmptyDetailPlaceholder()),
      ],
    );
  }
}

class _EmptyDetailPlaceholder extends StatelessWidget {
  const _EmptyDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            l10n.selectItem,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
