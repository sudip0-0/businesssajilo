import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/quotes_repository.dart';

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

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await ref.read(quotesRepositoryProvider).accept(
            widget.quoteId,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
      await ref.read(quotesRepositoryProvider).reject(
            widget.quoteId,
            comment: _commentController.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            return Center(child: Text(snapshot.error.toString()));
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
              if (quote.status.name == 'sent') ...[
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
                        onPressed: _loading ? null : _accept,
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
