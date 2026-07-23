import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../layout/web_bento_grid.dart';
import '../theme/web_palette.dart';
import '../theme/web_typography.dart';

enum WebTrendDirection { up, down, neutral }

class WebStatTile extends StatefulWidget {
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
  State<WebStatTile> createState() => _WebStatTileState();
}

class _WebStatTileState extends State<WebStatTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: WebBentoTile(
        onTap: widget.onTap,
        elevated: true,
        minHeight: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brass ledger rule — draws in on hover.
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _hovered ? 44 : 0,
              height: 2,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: WebPalette.brass,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: WebPalette.navyWash,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: WebPalette.navy.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(widget.icon, size: 18, color: WebPalette.navy),
                ),
                const Spacer(),
                if (widget.trend != null)
                  Flexible(
                    child: _TrendBadge(
                      direction: widget.trend!,
                      label: widget.trendLabel,
                    ),
                  ),
                if (widget.onTap != null)
                  Icon(
                    PhosphorIconsRegular.arrowUpRight,
                    size: 15,
                    color: _hovered ? WebPalette.navy : WebPalette.inkFaint,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.label.toUpperCase(),
              style: WebTypography.eyebrow(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              widget.value,
              style: WebTypography.metricValue(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
              height: 18,
              child: widget.subtitle != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: WebPalette.inkSoft,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : null,
            ),
          ],
        ),
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
    final (color, wash, icon) = switch (direction) {
      WebTrendDirection.up => (
        WebPalette.success,
        WebPalette.successWash,
        PhosphorIconsRegular.trendUp,
      ),
      WebTrendDirection.down => (
        WebPalette.danger,
        WebPalette.dangerWash,
        PhosphorIconsRegular.trendDown,
      ),
      WebTrendDirection.neutral => (
        WebPalette.warning,
        WebPalette.warningWash,
        PhosphorIconsRegular.minus,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          if (label != null) ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label!.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
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
