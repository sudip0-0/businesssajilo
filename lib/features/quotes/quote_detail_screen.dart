import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/error_state.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/quotes_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/quote.dart';
import '../orders/providers.dart';
import 'providers.dart';

class QuoteDetailScreen extends ConsumerStatefulWidget {
  const QuoteDetailScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _accept(Quote quote) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accept),
        content: Text(
          l10n.quoteAcceptConfirm(
            formatNpr(Paisa(quote.total), showPaisa: false),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.accept),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final updated = await ref.read(quotesRepositoryProvider).accept(
            widget.quoteId,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          );
      _invalidateOrder(updated.orderId);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context);
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.rejectComment)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final updated = await ref.read(quotesRepositoryProvider).reject(
            widget.quoteId,
            comment: _commentController.text.trim(),
          );
      _invalidateOrder(updated.orderId);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.actionFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _invalidateOrder(String orderId) {
    ref.invalidate(orderDetailProvider(orderId));
    ref.invalidate(orderQuotesProvider(orderId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quoteDetail)),
      body: FutureBuilder(
        future: ref.read(quotesRepositoryProvider).get(widget.quoteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(message: l10n.loadingFailed);
          }
          final quote = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.quoteVersion(quote.version),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              ...quote.items.map(
                (item) => ListTile(
                  title: Text(item.productName ?? '—'),
                  subtitle: Text(
                    '${item.qty} × ${formatNpr(Paisa(item.rate), showPaisa: false)}',
                  ),
                  trailing: Text(
                    formatNpr(Paisa(item.lineTotal), showPaisa: false),
                  ),
                ),
              ),
              const Divider(),
              Text(
                '${l10n.grandTotal}: ${formatNpr(Paisa(quote.total), showPaisa: false)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (quote.status == QuoteStatus.sent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(labelText: l10n.rejectComment),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _reject,
                        child: Text(l10n.reject),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _loading ? null : () => _accept(quote),
                        child: Text(l10n.accept),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
