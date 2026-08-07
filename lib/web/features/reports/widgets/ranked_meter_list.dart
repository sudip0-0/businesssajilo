import 'package:flutter/material.dart';

import '../../../theme/web_palette.dart';
import '../../../theme/web_typography.dart';
import '../../../ui/web_empty_state.dart';

class RankedMeterItem {
  const RankedMeterItem({
    required this.id,
    required this.label,
    required this.valueLabel,
    required this.metric,
    this.subtitle,
  });

  final String id;
  final String label;
  final String valueLabel;
  final int metric;
  final String? subtitle;
}

/// Ranked list with thin proportional meter bars (Digital Ledger).
class RankedMeterList extends StatelessWidget {
  const RankedMeterList({
    super.key,
    required this.items,
    this.onTap,
    this.emptyMessage,
    this.emptyIcon,
    this.maxItems = 10,
  });

  final List<RankedMeterItem> items;
  final void Function(RankedMeterItem item)? onTap;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(maxItems).toList();
    if (visible.isEmpty) {
      return WebEmptyState(
        message: emptyMessage ?? '—',
        icon: emptyIcon ?? Icons.inbox_outlined,
      );
    }

    final rawMax = visible
        .map((e) => e.metric)
        .fold<int>(0, (a, b) => a > b ? a : b);
    // Avoid `clamp(1, 1 << 62)` — on web, shifts are 32-bit so `1 << 62`
    // becomes 0 and clamp throws "Invalid argument: 1".
    final maxMetric = rawMax <= 0 ? 1 : rawMax;

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++)
          _RankedRow(
            rank: i + 1,
            item: visible[i],
            fraction: visible[i].metric / maxMetric,
            onTap: onTap == null ? null : () => onTap!(visible[i]),
          ),
      ],
    );
  }
}

class _RankedRow extends StatefulWidget {
  const _RankedRow({
    required this.rank,
    required this.item,
    required this.fraction,
    this.onTap,
  });

  final int rank;
  final RankedMeterItem item;
  final double fraction;
  final VoidCallback? onTap;

  @override
  State<_RankedRow> createState() => _RankedRowState();
}

class _RankedRowState extends State<_RankedRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? WebPalette.paperDeep.withValues(alpha: 0.55) : null,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${widget.rank}',
                        style: WebTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: WebPalette.inkSoft,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (widget.item.subtitle != null)
                            Text(
                              widget.item.subtitle!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: WebPalette.inkSoft),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.item.valueLabel,
                      style: WebTypography.mono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: WebPalette.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: widget.fraction.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: WebPalette.paperDeep,
                    color: WebPalette.navy.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
