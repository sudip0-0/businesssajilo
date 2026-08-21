import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/feature_flags.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bs_date.dart';
import '../../core/utils/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/quote.dart';
import '../auth/providers/auth_provider.dart';
import '../orders/providers.dart';
import 'providers.dart';

/// Role-prefixed route for [path] on web; plain mobile path otherwise.
/// Web routes are nested under `/owner`, `/sales`, or `/customer`.
String _routeForPlatform(BuildContext context, String mobilePath) {
  if (!kIsWeb) return mobilePath;
  final segments = GoRouterState.of(context).uri.pathSegments;
  final base = segments.isNotEmpty ? '/${segments.first}' : '/owner';
  return '$base$mobilePath';
}

/// Quote status card shown on the order detail screen (mobile + web).
///
/// Staff (owner/sales) can send a new quote or open the latest one;
/// customers see the pending quote with a shortcut to accept/reject.
class OrderQuoteSection extends ConsumerWidget {
  const OrderQuoteSection({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).value?.member?.role;
    if (role == null || role == Role.warehouse) {
      return const SizedBox.shrink();
    }

    final quotesAsync = ref.watch(orderQuotesProvider(orderId));
    return quotesAsync.maybeWhen(
      data: (quotes) {
        final latest = quotes.isEmpty ? null : quotes.first;
        if (role == Role.customer) {
          return _CustomerQuoteCard(
            orderId: orderId,
            latestSent: quotes.where((q) => q.status == QuoteStatus.sent).firstOrNull,
          );
        }
        return _StaffQuoteCard(orderId: orderId, latest: latest);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

bool isQuoteExpired(Quote quote) =>
    quote.status == QuoteStatus.sent &&
    quote.createdAt != null &&
    DateTime.now().toUtc().isAfter(quoteExpiresAt(quote.createdAt!));

String quoteStatusLabel(AppLocalizations l10n, Quote quote) =>
    switch (quote.status) {
      QuoteStatus.accepted => l10n.quoteAccepted,
      QuoteStatus.rejected => l10n.quoteRejected,
      QuoteStatus.superseded => l10n.quoteSuperseded,
      QuoteStatus.sent when isQuoteExpired(quote) => l10n.quoteExpired,
      QuoteStatus.sent => l10n.quoteSent,
    };

class _StaffQuoteCard extends ConsumerWidget {
  const _StaffQuoteCard({required this.orderId, this.latest});

  final String orderId;
  final Quote? latest;

  Future<void> _openBuilder(BuildContext context) async {
    await context.push(
      _routeForPlatform(context, '/order/$orderId/quote/new'),
    );
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(orderQuotesProvider(orderId));
    ref.invalidate(orderDetailProvider(orderId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasPending = latest != null &&
        latest!.status == QuoteStatus.sent &&
        !isQuoteExpired(latest!);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.quotes,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (latest != null)
                  Text(
                    quoteStatusLabel(l10n, latest!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: BsColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            if (latest == null) ...[
              const SizedBox(height: 4),
              Text(l10n.noAcceptedQuote, style: theme.textTheme.bodySmall),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.quoteVersion(latest!.version)} · '
                '${formatNpr(Paisa(latest!.total), showPaisa: false)}',
                style: theme.textTheme.bodyMedium,
              ),
              if (latest!.status == QuoteStatus.sent &&
                  latest!.createdAt != null)
                Text(
                  l10n.quoteExpiresOn(
                    BsDate.both(quoteExpiresAt(latest!.createdAt!)),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!hasPending)
                  FilledButton.icon(
                    onPressed: () async {
                      await _openBuilder(context);
                      _invalidate(ref);
                    },
                    icon: const Icon(Icons.request_quote_outlined, size: 18),
                    label: Text(
                      latest == null ? l10n.sendQuote : l10n.requote,
                    ),
                  ),
                if (latest != null)
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      _routeForPlatform(context, '/quote/${latest!.id}'),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(l10n.viewQuote),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerQuoteCard extends ConsumerWidget {
  const _CustomerQuoteCard({required this.orderId, this.latestSent});

  final String orderId;
  final Quote? latestSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (latestSent == null) return const SizedBox.shrink();
    final quote = latestSent!;
    final expired = isQuoteExpired(quote);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: expired ? null : BsColors.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    expired ? l10n.quoteExpired : l10n.notifQuoteReceived,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  formatNpr(Paisa(quote.total), showPaisa: false),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (!expired && quote.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.quoteExpiresOn(
                    BsDate.both(quoteExpiresAt(quote.createdAt!)),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push(
                _routeForPlatform(context, '/quote/${quote.id}'),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(expired ? l10n.viewQuote : l10n.respond),
            ),
          ],
        ),
      ),
    );
  }
}
