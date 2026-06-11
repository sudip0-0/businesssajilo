import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../domain/models/order_item.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/quotes_repository.dart';
import '../auth/providers/auth_provider.dart';
import '../orders/providers.dart';

class _DraftLine {
  _DraftLine({
    required this.productId,
    required this.name,
    required this.qty,
    required this.rate,
  })  : discount = 0,
        rateController = TextEditingController(
          text: formatNpr(Paisa(rate), showPaisa: false),
        ),
        discountController = TextEditingController();

  final String productId;
  final String name;
  int qty;
  int rate;
  int discount;
  final TextEditingController rateController;
  final TextEditingController discountController;

  int get lineTotal =>
      lineTotalPaisa(qty: qty, ratePaisa: rate, discountPaisa: discount);

  bool get discountValid => isValidLineDiscount(
        qty: qty,
        ratePaisa: rate,
        discountPaisa: discount,
      );

  void dispose() {
    rateController.dispose();
    discountController.dispose();
  }
}

class QuoteBuilderScreen extends ConsumerStatefulWidget {
  const QuoteBuilderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _QuoteBuilderScreenState extends ConsumerState<QuoteBuilderScreen> {
  final _lines = <_DraftLine>[];
  bool _loading = false;
  bool _initialized = false;

  int get _total => itemsTotalPaisa(_lines.map((l) => l.lineTotal));

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _sendQuote() async {
    final l10n = AppLocalizations.of(context);
    final member = ref.read(authProvider).value?.member;
    if (member == null || _lines.isEmpty) return;

    if (_lines.any((l) => !l.discountValid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.discountExceedsLine)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(quotesRepositoryProvider).sendQuote(
            orderId: widget.orderId,
            createdByMemberId: member.id,
            total: _total,
            lines: _lines
                .map(
                  (l) => QuoteLineInput(
                    productId: l.productId,
                    qty: l.qty,
                    rate: l.rate,
                    discount: l.discount,
                    lineTotal: l.lineTotal,
                  ),
                )
                .toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.quoteSent)),
        );
        Navigator.pop(context, true);
      }
    } on QuoteSendException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
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

  Future<void> _initLines(List<OrderItem> items) async {
    final productsRepo = ref.read(productsRepositoryProvider);
    for (final item in items) {
      var rate = 0;
      try {
        final product = await productsRepo.get(item.productId);
        rate = product.referencePrice;
      } catch (_) {}
      _lines.add(
        _DraftLine(
          productId: item.productId,
          name: item.productName ?? '—',
          qty: item.qty,
          rate: rate,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sendQuote)),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: l10n.loadingFailed,
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (order) {
          if (!_initialized) {
            _initialized = true;
            _initLines(order.items);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) {
                    final line = _lines[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.name,
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                            if (line.rate == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Chip(
                                  avatar: const Icon(
                                    Icons.warning_amber_outlined,
                                    size: 18,
                                  ),
                                  label: Text(l10n.rateMissing),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            Row(
                              children: [
                                Text(l10n.quantity),
                                const SizedBox(width: 8),
                                QtyStepper(
                                  value: line.qty,
                                  min: 1,
                                  onChanged: (v) =>
                                      setState(() => line.qty = v),
                                ),
                              ],
                            ),
                            TextField(
                              controller: line.rateController,
                              decoration:
                                  InputDecoration(labelText: l10n.rate),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() {
                                line.rate =
                                    parseNpr(v)?.value ?? line.rate;
                              }),
                            ),
                            TextField(
                              controller: line.discountController,
                              decoration: InputDecoration(
                                labelText: l10n.lineDiscount,
                                errorText: line.discountValid
                                    ? null
                                    : l10n.discountExceedsLine,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() {
                                line.discount = parseNpr(v)?.value ?? 0;
                              }),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${l10n.lineTotal}: ${formatNpr(Paisa(line.lineTotal), showPaisa: false)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${l10n.grandTotal}: ${formatNpr(Paisa(_total), showPaisa: false)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loading || _lines.isEmpty ? null : _sendQuote,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.sendQuote),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
