import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feature_flags.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/submit_action.dart';
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
  }) : discount = 0,
       rateController = TextEditingController(text: formatNpr(Paisa(rate))),
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

  int? get tryLineTotal =>
      tryLineTotalPaisa(qty: qty, ratePaisa: rate, discountPaisa: discount);

  bool get discountValid =>
      isValidLineDiscount(qty: qty, ratePaisa: rate, discountPaisa: discount);

  void dispose() {
    rateController.dispose();
    discountController.dispose();
  }
}

class QuoteBuilderScreen extends ConsumerStatefulWidget {
  const QuoteBuilderScreen({
    super.key,
    required this.orderId,
    this.embedded = false,
  });

  final String orderId;
  final bool embedded;

  @override
  ConsumerState<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _QuoteBuilderScreenState extends ConsumerState<QuoteBuilderScreen> {
  final _lines = <_DraftLine>[];
  bool _loading = false;
  bool _initialized = false;
  bool _draftLoading = true;
  Object? _draftError;
  final _formKey = GlobalKey<FormState>();

  int get _total => itemsTotalPaisa(_lines.map((l) => l.lineTotal));

  int? get _tryTotal {
    final lineTotals = <int>[];
    for (final line in _lines) {
      final total = line.tryLineTotal;
      if (total == null) return null;
      lineTotals.add(total);
    }
    return tryItemsTotalPaisa(lineTotals);
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _sendQuote() async {
    if (_loading || _draftLoading || _draftError != null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final member = ref.read(authProvider).value?.member;
    if (member == null || _lines.isEmpty) return;

    if (_tryTotal == null) {
      showBsSnackBar(context, message: l10n.invalidNumber);
      return;
    }

    if (_lines.any((l) => !l.discountValid)) {
      showBsSnackBar(context, message: l10n.discountExceedsLine);
      return;
    }

    setState(() => _loading = true);
    final ok = await runSubmitAction(
      context,
      action: () async {
        await ref
            .read(quotesRepositoryProvider)
            .sendQuote(
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
      },
      successMessage: l10n.quoteSent,
    );
    if (ok && mounted) Navigator.pop(context, true);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _initLines(List<OrderItem> items) async {
    final productsRepo = ref.read(productsRepositoryProvider);
    final quotesRepo = ref.read(quotesRepositoryProvider);
    final customerId = ref
        .read(orderDetailProvider(widget.orderId))
        .value
        ?.customerId;
    final loaded = <_DraftLine>[];
    try {
      for (final item in items) {
        final product = await productsRepo.get(item.productId);
        final lastQuoted = customerId == null
            ? null
            : await quotesRepo.lastQuotedRate(
                customerId: customerId,
                productId: item.productId,
              );
        loaded.add(
          _DraftLine(
            productId: item.productId,
            name: item.productName ?? product.name,
            qty: item.qty,
            rate: resolveQuoteRate(
              lastQuotedPaisa: lastQuoted,
              referencePaisa: product.referencePrice,
            ),
          ),
        );
      }
      if (!mounted) {
        for (final line in loaded) {
          line.dispose();
        }
        return;
      }
      setState(() {
        _lines.addAll(loaded);
        _draftLoading = false;
      });
    } catch (e) {
      for (final line in loaded) {
        line.dispose();
      }
      if (mounted) {
        setState(() {
          _draftError = e;
          _draftLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    final body = orderAsync.when(
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

        if (_draftLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_draftError != null) {
          return ErrorState(
            message: l10n.loadingFailed,
            onRetry: () {
              setState(() {
                _draftError = null;
                _draftLoading = true;
              });
              _initLines(order.items);
            },
          );
        }
        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
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
                            Text(
                              line.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
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
                            TextFormField(
                              controller: line.rateController,
                              validator: (value) {
                                final parsed = parseNpr(value ?? '');
                                if (parsed == null || parsed.value < 0) {
                                  return l10n.invalidNumber;
                                }
                                if (tryLineGrossPaisa(
                                      qty: line.qty,
                                      ratePaisa: parsed.value,
                                    ) ==
                                    null) {
                                  return l10n.invalidNumber;
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: l10n.rate,
                                errorText: line.tryLineTotal == null
                                    ? l10n.invalidNumber
                                    : null,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (v) => setState(() {
                                line.rate = parseNpr(v)?.value ?? line.rate;
                              }),
                            ),
                            TextFormField(
                              controller: line.discountController,
                              validator: (value) {
                                final parsed = parseNpr(
                                  value == null || value.isEmpty ? '0' : value,
                                );
                                if (parsed == null || parsed.value < 0) {
                                  return l10n.invalidNumber;
                                }
                                final gross = tryLineGrossPaisa(
                                  qty: line.qty,
                                  ratePaisa: line.rate,
                                );
                                if (gross == null) return l10n.invalidNumber;
                                return parsed.value > gross
                                    ? l10n.discountExceedsLine
                                    : null;
                              },
                              decoration: InputDecoration(
                                labelText: l10n.lineDiscount,
                                errorText: line.tryLineTotal == null
                                    ? l10n.invalidNumber
                                    : line.discountValid
                                    ? null
                                    : l10n.discountExceedsLine,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (v) => setState(() {
                                line.discount = parseNpr(v)?.value ?? 0;
                              }),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${l10n.lineTotal}: ${line.tryLineTotal == null ? l10n.invalidNumber : formatNpr(Paisa(line.tryLineTotal!))}',
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
                      '${l10n.grandTotal}: ${_tryTotal == null ? l10n.invalidNumber : formatNpr(Paisa(_tryTotal!))}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loading || _lines.isEmpty ? null : _sendQuote,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.sendQuote),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sendQuote)),
      body: body,
    );
  }
}
