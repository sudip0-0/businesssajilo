import 'package:flutter/material.dart';

import '../theme/web_palette.dart';
import '../theme/web_tokens.dart';
import '../theme/web_typography.dart';

/// Left-aligned page header with optional breadcrumbs and actions.
class WebPageHeader extends StatelessWidget {
  const WebPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs = const [],
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<String> breadcrumbs;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = context.isWebCompact;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TitleBlock(
              theme: theme,
              title: title,
              subtitle: subtitle,
              breadcrumbs: breadcrumbs,
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TitleBlock(
              theme: theme,
              title: title,
              subtitle: subtitle,
              breadcrumbs: breadcrumbs,
            ),
          ),
          if (actions.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.theme,
    required this.title,
    this.subtitle,
    this.breadcrumbs = const [],
  });

  final ThemeData theme;
  final String title;
  final String? subtitle;
  final List<String> breadcrumbs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (breadcrumbs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < breadcrumbs.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: WebPalette.brass,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Text(
                    breadcrumbs[i].toUpperCase(),
                    style: WebTypography.eyebrow(
                      color: i == breadcrumbs.length - 1
                          ? WebPalette.inkSoft
                          : WebPalette.inkFaint,
                    ).copyWith(fontSize: 10.5),
                  ),
                ],
              ],
            ),
          ),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(color: WebPalette.ink),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: WebPalette.inkSoft,
            ),
          ),
        ],
      ],
    );
  }
}
