import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../theme/web_tokens.dart';

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
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
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              breadcrumbs.join(' / '),
              style: theme.textTheme.labelSmall?.copyWith(
                color: BsColors.outline,
                letterSpacing: 0.5,
              ),
            ),
          ),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: BsColors.textCharcoal,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: BsColors.outline,
            ),
          ),
        ],
      ],
    );
  }
}
