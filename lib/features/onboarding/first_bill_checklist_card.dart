import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../auth/providers/auth_provider.dart';
import '../billing/bill_form_screen.dart';
import '../billing/providers.dart';
import '../customers/add_customer_sheet.dart';
import '../customers/providers.dart';
import '../inventory/product_form_screen.dart';
import '../inventory/providers.dart';
import '../settings/settings_screen.dart';
import 'first_bill_checklist_provider.dart';

/// Compact dismissible onboarding checklist card for the mobile Owner Dashboard.
class FirstBillChecklistCard extends ConsumerWidget {
  const FirstBillChecklistCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklist = ref.watch(firstBillChecklistProvider).value;
    if (checklist == null || !checklist.shouldShow) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = checklist.completedCount / checklist.totalCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(BsSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.checklist_rounded,
                    size: 20,
                    color: BsColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.firstBillChecklistTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: BsColors.textCharcoal,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.firstBillChecklistDismiss,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () =>
                        dismissFirstBillChecklist(ref, checklist.businessId),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(BsRadii.sm),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.firstBillChecklistProgress(
                      checklist.completedCount,
                      checklist.totalCount,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: BsColors.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ChecklistStepRow(
                title: l10n.checklistStepProfileTitle,
                done: checklist.businessProfileReady,
                actionLabel: l10n.checklistStepProfileAction,
                onAction: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(l10n.settings)),
                        body: const SettingsScreen(),
                      ),
                    ),
                  );
                  ref.invalidate(currentBusinessProvider);
                },
              ),
              _ChecklistStepRow(
                title: l10n.checklistStepProductTitle,
                done: checklist.hasProduct,
                actionLabel: l10n.addProduct,
                onAction: () async {
                  final saved = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductFormScreen(),
                    ),
                  );
                  if (saved == true) {
                    bumpInventoryRevision(ref);
                  }
                },
              ),
              _ChecklistStepRow(
                title: l10n.checklistStepCustomerTitle,
                done: checklist.hasCustomer,
                actionLabel: l10n.addCustomer,
                onAction: () async {
                  final created = await showAdaptiveSheet<bool>(
                    context: context,
                    title: l10n.addCustomer,
                    child: const AddCustomerSheet(),
                  );
                  if (created == true) {
                    bumpCustomersRevision(ref);
                  }
                },
              ),
              _ChecklistStepRow(
                title: l10n.checklistStepBillTitle,
                done: checklist.hasBill,
                actionLabel: l10n.newBill,
                onAction: () async {
                  final saved = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const BillFormScreen()),
                  );
                  if (saved == true) {
                    bumpBillingRevision(ref);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistStepRow extends StatelessWidget {
  const _ChecklistStepRow({
    required this.title,
    required this.done,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final bool done;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? BsColors.success : BsColors.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: done ? BsColors.outline : BsColors.textCharcoal,
                decoration: done ? TextDecoration.lineThrough : null,
                fontWeight: done ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            Text(
              l10n.checklistCompleted,
              style: theme.textTheme.labelSmall?.copyWith(
                color: BsColors.success,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
