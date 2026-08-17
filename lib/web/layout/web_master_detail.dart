import 'dart:math' as math;

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

  static const double _minDetailWidth = 280;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.webTokens;
    final preferredPane =
        listWidth ??
        (context.isWebWide ? tokens.wideListPaneWidth : tokens.listPaneWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null;
        final available = constraints.maxWidth;
        // Prefer single-pane when the content area can't fit list + usable detail
        // (accounts for sidebar eating window width on tablet).
        final useSplit =
            !context.isWebCompact &&
            available >= preferredPane + _minDetailWidth;
        final paneWidth = useSplit
            ? math.min(
                preferredPane,
                math.max(280.0, available - _minDetailWidth),
              )
            : preferredPane;

        if (!useSplit) {
          final child = hasSelection && detail != null ? detail! : list;
          if (height == null) return child;
          return SizedBox(width: available, height: height, child: child);
        }

        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: paneWidth, height: height, child: list),
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
          ),
        );
      },
    );
  }
}
