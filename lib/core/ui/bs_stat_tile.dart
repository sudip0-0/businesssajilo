import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum BsTrendDirection { up, down, neutral }

/// KPI metric card per Design.md — shared by mobile and web.
class BsStatTile extends StatelessWidget {
  const BsStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon = Icons.trending_up,
    this.onTap,
    this.subtitle,
    this.trend,
    this.trendLabel,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? subtitle;
  final BsTrendDirection? trend;
  final String? trendLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final minHeight = compact ? 112.0 : 132.0;

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BsRadii.lg),
        side: const BorderSide(color: BsColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BsRadii.lg),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BsRadii.lg),
            boxShadow: BsElevation.level2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    _TrendBadge(direction: trend!, label: trendLabel),
                  if (onTap != null)
                    Icon(Icons.arrow_forward, size: 16, color: scheme.outline),
                ],
              ),
              const Spacer(),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.outline,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: BsColors.textCharcoal,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.direction, this.label});

  final BsTrendDirection direction;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (direction) {
      BsTrendDirection.up => (BsColors.secondary, Icons.trending_up),
      BsTrendDirection.down => (BsColors.danger, Icons.trending_down),
      BsTrendDirection.neutral => (BsColors.outline, Icons.remove),
    };

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BsRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
