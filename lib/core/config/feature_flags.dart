import '../../domain/models/business.dart';

/// Launch-time plan labels. Gating UI is not enabled until v2.
abstract final class FeatureFlags {
  static const free = 'free';
  static const pro = 'pro';

  static bool isPaidPlan(String plan) => plan != free && plan.isNotEmpty;

  static String labelFor(Business business) {
    final plan = business.subscriptionPlan.trim();
    if (plan.isEmpty) return free;
    return plan;
  }
}

/// Preferred quote line rate: last quoted for this customer, else catalog ref.
int resolveQuoteRate({int? lastQuotedPaisa, required int referencePaisa}) {
  if (lastQuotedPaisa != null && lastQuotedPaisa > 0) return lastQuotedPaisa;
  return referencePaisa < 0 ? 0 : referencePaisa;
}

Duration get defaultQuoteTtl => const Duration(days: 7);

DateTime quoteExpiresAt(DateTime createdAt) => createdAt.add(defaultQuoteTtl);
