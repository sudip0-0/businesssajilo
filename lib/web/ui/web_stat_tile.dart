import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../layout/web_bento_grid.dart';
import '../theme/web_typography.dart';

enum WebTrendDirection { up, down, neutral }

class WebStatTile extends StatelessWidget {
  const WebStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon = PhosphorIconsRegular.chartLineUp,
    this.onTap,
    this.subtitle,
    this.trend,
    this.trendLabel,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? subtitle;
  final WebTrendDirection? trend;
  final String? trendLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return WebBentoTile(
      onTap: onTap,
      elevated: true,
      minHeight: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: BsColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(BsRadii.md),
                ),
                child: Icon(icon, size: 18, color: BsColors.primary),
              ),
              const Spacer(),
              if (trend != null)
                Flexible(
                  child: _TrendBadge(direction: trend!, label: trendLabel),
                ),
              if (onTap != null)
                Icon(
                  PhosphorIconsRegular.arrowRight,
                  size: 16,
                  color: scheme.outline,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.outline,
              letterSpacing: 0.8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WebTypography.metricValue(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: 18,
            child: subtitle != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.direction, this.label});

  final WebTrendDirection direction;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (direction) {
      WebTrendDirection.up => (BsColors.secondary, PhosphorIconsRegular.trendUp),
      WebTrendDirection.down => (BsColors.danger, PhosphorIconsRegular.trendDown),
      WebTrendDirection.neutral => (BsColors.outline, PhosphorIconsRegular.minus),
    };

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BsRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          if (label != null) ...[
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
