import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/money.dart';
import '../../../theme/web_palette.dart';
import '../../../theme/web_typography.dart';

/// Stacked horizontal aging bar. Optional [selectedBucket] highlights a
/// segment; tapping a segment calls [onBucketSelected] (null = clear).
class AgingDistributionBar extends StatelessWidget {
  const AgingDistributionBar({
    super.key,
    required this.bucket0to30,
    required this.bucket31to60,
    required this.bucket60plus,
    this.selectedBucket,
    this.onBucketSelected,
    this.height = 14,
    this.showLegend = true,
    this.compact = false,
  });

  final int bucket0to30;
  final int bucket31to60;
  final int bucket60plus;
  final String? selectedBucket;
  final ValueChanged<String?>? onBucketSelected;
  final double height;
  final bool showLegend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = bucket0to30 + bucket31to60 + bucket60plus;
    final segments = <_Segment>[
      _Segment('0_30', bucket0to30, WebPalette.success, l10n.aging0to30),
      _Segment('31_60', bucket31to60, WebPalette.warning, l10n.aging31to60),
      _Segment('60_plus', bucket60plus, WebPalette.danger, l10n.aging60plus),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: height,
            child: total <= 0
                ? const ColoredBox(color: WebPalette.paperDeep)
                : Row(
                    children: [
                      for (final s in segments)
                        if (s.amount > 0)
                          Expanded(
                            flex: s.amount,
                            child: MouseRegion(
                              cursor: onBucketSelected != null
                                  ? SystemMouseCursors.click
                                  : SystemMouseCursors.basic,
                              child: GestureDetector(
                                onTap: onBucketSelected == null
                                    ? null
                                    : () => onBucketSelected!(
                                        selectedBucket == s.key ? null : s.key,
                                      ),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 160),
                                  opacity: selectedBucket == null ||
                                          selectedBucket == s.key
                                      ? 1
                                      : 0.35,
                                  child: ColoredBox(color: s.color),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
          ),
        ),
        if (showLegend) ...[
          SizedBox(height: compact ? 8 : 12),
          Wrap(
            spacing: compact ? 12 : 16,
            runSpacing: 6,
            children: [
              for (final s in segments)
                InkWell(
                  onTap: onBucketSelected == null
                      ? null
                      : () => onBucketSelected!(
                          selectedBucket == s.key ? null : s.key,
                        ),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.label,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: selectedBucket == null ||
                                        selectedBucket == s.key
                                    ? WebPalette.ink
                                    : WebPalette.inkFaint,
                                fontWeight: selectedBucket == s.key
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 6),
                          Text(
                            formatNpr(Paisa(s.amount), showPaisa: false),
                            style: WebTypography.mono(
                              fontSize: 11.5,
                              color: WebPalette.inkSoft,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Segment {
  const _Segment(this.key, this.amount, this.color, this.label);
  final String key;
  final int amount;
  final Color color;
  final String label;
}
