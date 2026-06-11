import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../l10n/app_localizations.dart';

/// Compact horizontal timeline of the happy-path order flow:
/// placed → quoted → accepted → confirmed → packed → dispatched → billed.
/// Done/current/future steps are visually distinct using theme colors.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.status});

  final OrderStatus status;

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.quoted,
    OrderStatus.accepted,
    OrderStatus.confirmed,
    OrderStatus.packed,
    OrderStatus.dispatched,
    OrderStatus.billed,
  ];

  static String _label(AppLocalizations l10n, OrderStatus s) => switch (s) {
        OrderStatus.placed => l10n.statusPlaced,
        OrderStatus.quoted => l10n.statusQuoted,
        OrderStatus.accepted => l10n.statusAccepted,
        OrderStatus.confirmed => l10n.statusConfirmed,
        OrderStatus.packed => l10n.statusPacked,
        OrderStatus.dispatched => l10n.statusDispatched,
        OrderStatus.billed => l10n.statusBilled,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    // Off-path statuses (rejected/cancelled/closed/draft) don't map cleanly
    // to a progress index; hide the timeline for those.
    final currentIndex = _steps.indexOf(
      status == OrderStatus.closed ? OrderStatus.billed : status,
    );
    if (currentIndex < 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(top: 11),
                child: Container(
                  width: 16,
                  height: 2,
                  color: i <= currentIndex
                      ? scheme.primary
                      : scheme.outlineVariant,
                ),
              ),
            _TimelineStep(
              label: _label(l10n, _steps[i]),
              state: i < currentIndex
                  ? _StepState.done
                  : i == currentIndex
                      ? _StepState.current
                      : _StepState.future,
            ),
          ],
        ],
      ),
    );
  }
}

enum _StepState { done, current, future }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fill, border, content) = switch (state) {
      _StepState.done => (
          scheme.primary,
          scheme.primary,
          Icon(Icons.check, size: 14, color: scheme.onPrimary),
        ),
      _StepState.current => (
          scheme.primaryContainer,
          scheme.primary,
          Icon(Icons.circle, size: 10, color: scheme.primary),
        ),
      _StepState.future => (
          Colors.transparent,
          scheme.outlineVariant,
          const SizedBox.shrink(),
        ),
    };
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: state == _StepState.future ? scheme.outline : scheme.onSurface,
          fontWeight:
              state == _StepState.current ? FontWeight.w700 : FontWeight.w400,
        );

    return Semantics(
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 2),
            ),
            child: Center(child: content),
          ),
          const SizedBox(height: 4),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}
