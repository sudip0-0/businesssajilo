import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
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
