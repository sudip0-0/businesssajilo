import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/layout/bs_breakpoints.dart';
import '../../../../features/onboarding/first_bill_checklist_provider.dart';
import '../../../layout/web_bento_grid.dart';
import '../../../theme/web_palette.dart';
import '../../../theme/web_typography.dart';

/// Digital Ledger styled dismissible onboarding checklist for Web Owner Dashboard.
class WebFirstBillChecklistCard extends ConsumerWidget {
  const WebFirstBillChecklistCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklist = ref.watch(firstBillChecklistProvider).value;
    if (checklist == null || !checklist.shouldShow) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = checklist.completedCount / checklist.totalCount;

    final steps = [
      _WebChecklistStep(
        title: l10n.checklistStepProfileTitle,
        done: checklist.businessProfileReady,
        actionLabel: l10n.checklistStepProfileAction,
        icon: PhosphorIconsRegular.storefront,
        onAction: () => context.go('/owner/settings'),
      ),
      _WebChecklistStep(
        title: l10n.checklistStepProductTitle,
        done: checklist.hasProduct,
        actionLabel: l10n.addProduct,
        icon: PhosphorIconsRegular.package,
        onAction: () => context.push('/owner/inventory/new'),
      ),
      _WebChecklistStep(
        title: l10n.checklistStepCustomerTitle,
        done: checklist.hasCustomer,
        actionLabel: l10n.addCustomer,
        icon: PhosphorIconsRegular.userPlus,
        onAction: () => context.go('/owner/customers/new'),
      ),
      _WebChecklistStep(
        title: l10n.checklistStepBillTitle,
        done: checklist.hasBill,
        actionLabel: l10n.newBill,
        icon: PhosphorIconsRegular.receipt,
        onAction: () => context.push('/owner/billing/new'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: WebBentoTile(
        minHeight: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: WebPalette.brassWash,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: WebPalette.brass.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.listChecks,
                    size: 16,
                    color: WebPalette.brassDeep,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.firstBillChecklistTitle,
                        style: WebTypography.serif(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: WebPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.firstBillChecklistProgress(
                          checklist.completedCount,
                          checklist.totalCount,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WebPalette.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.firstBillChecklistDismiss,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      dismissFirstBillChecklist(ref, checklist.businessId),
                  icon: const Icon(PhosphorIconsRegular.x, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: WebPalette.paperDeep,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  WebPalette.brass,
                ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= BsBreakpoints.tablet;
                if (!twoColumns) {
                  return Column(
                    children: [
                      for (var i = 0; i < steps.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _WebChecklistStepTile(step: steps[i]),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _WebChecklistStepTile(step: steps[0])),
                        const SizedBox(width: 10),
                        Expanded(child: _WebChecklistStepTile(step: steps[1])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _WebChecklistStepTile(step: steps[2])),
                        const SizedBox(width: 10),
                        Expanded(child: _WebChecklistStepTile(step: steps[3])),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WebChecklistStep {
  const _WebChecklistStep({
    required this.title,
    required this.done,
    required this.actionLabel,
    required this.icon,
    required this.onAction,
  });

  final String title;
  final bool done;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onAction;
}

class _WebChecklistStepTile extends StatelessWidget {
  const _WebChecklistStepTile({required this.step});

  final _WebChecklistStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: step.done ? WebPalette.paperDeep : WebPalette.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: step.done
              ? WebPalette.success.withValues(alpha: 0.3)
              : WebPalette.hairline,
        ),
      ),
      child: Row(
        children: [
          Icon(
            step.done ? PhosphorIconsFill.checkCircle : step.icon,
            size: 18,
            color: step.done ? WebPalette.success : WebPalette.navy,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: step.done ? WebPalette.inkSoft : WebPalette.ink,
                decoration: step.done ? TextDecoration.lineThrough : null,
                fontWeight: step.done ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (step.done)
            Text(
              l10n.checklistCompleted,
              style: theme.textTheme.labelSmall?.copyWith(
                color: WebPalette.success,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: const Size(0, 30),
              ),
              onPressed: step.onAction,
              child: Text(step.actionLabel),
            ),
        ],
      ),
    );
  }
}
