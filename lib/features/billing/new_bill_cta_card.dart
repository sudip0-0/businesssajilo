import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../customers/providers.dart';
import '../reports/dashboard/dashboard_invalidation.dart';
import 'bill_form_screen.dart';
import 'providers.dart';

/// Prominent dashboard call-to-action that opens the bill form.
///
/// Surfaces the primary revenue action (creating a bill) directly on the
/// dashboard so owners/sales don't have to switch to the Billing tab first.
/// Handles navigation and cache invalidation in one place.
class NewBillCtaCard extends ConsumerWidget {
  const NewBillCtaCard({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BillFormScreen()),
    );
    if (saved == true) {
      bumpBillingRevision(ref);
      ref.invalidate(billListProvider);
      ref.invalidate(todaysBillCountProvider);
      ref.invalidate(totalDuesProvider);
      invalidateOwnerDashboardWidget(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: BsColors.secondary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(BsRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BsSpacing.lg,
            vertical: BsSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BsColors.secondary,
                  borderRadius: BorderRadius.circular(BsRadii.lg),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: BsColors.onSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: BsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.newBill,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: BsColors.secondary,
                      ),
                    ),
                    Text(
                      l10n.createBillSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BsColors.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BsSpacing.sm),
              const Icon(
                Icons.arrow_forward_rounded,
                color: BsColors.secondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
