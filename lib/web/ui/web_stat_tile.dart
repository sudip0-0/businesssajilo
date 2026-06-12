import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../layout/web_bento_grid.dart';
import '../theme/web_typography.dart';

class WebStatTile extends StatelessWidget {
  const WebStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon = PhosphorIconsRegular.chartLineUp,
    this.onTap,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return WebBentoTile(
      onTap: onTap,
      minHeight: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const Spacer(),
              if (onTap != null)
                Icon(
                  PhosphorIconsRegular.arrowRight,
                  size: 16,
                  color: scheme.outline,
                ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.outline,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: WebTypography.monoData(context, fontSize: 28)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}
