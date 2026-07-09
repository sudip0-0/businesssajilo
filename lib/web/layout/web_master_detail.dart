import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../theme/web_tokens.dart';

/// URL-synced master-detail split for web list screens.
class WebMasterDetail extends StatelessWidget {
  const WebMasterDetail({
    super.key,
    required this.list,
    required this.detail,
    this.hasSelection = false,
    this.listWidth,
  });

  final Widget list;
  final Widget? detail;
  final bool hasSelection;
  final double? listWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.webTokens;
    final compact = context.isWebCompact;
    final paneWidth =
        listWidth ??
        (context.isWebWide ? tokens.wideListPaneWidth : tokens.listPaneWidth);

    if (compact) {
      return hasSelection && detail != null ? detail! : list;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: paneWidth, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          child:
              detail ??
              Center(
                child: Text(
                  l10n.selectItem,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
        ),
      ],
    );
  }
}
