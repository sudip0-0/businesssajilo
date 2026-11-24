import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feature_flags.dart';
import '../../core/l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';

/// Displays the current `businesses.subscription_plan`. Gating stays off until v2.
class SubscriptionPlanTile extends ConsumerWidget {
  const SubscriptionPlanTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final business = ref.watch(currentBusinessProvider).value;
    if (business == null) return const SizedBox.shrink();
    final rawPlan = FeatureFlags.labelFor(business).toLowerCase();
    final planLabel = switch (rawPlan) {
      FeatureFlags.free => l10n.planFree,
      FeatureFlags.pro => l10n.planPro,
      _ => FeatureFlags.labelFor(business),
    };
    return ListTile(
      leading: const Icon(Icons.workspace_premium_outlined),
      title: Text(l10n.subscriptionPlan),
      subtitle: Text(planLabel),
    );
  }
}
