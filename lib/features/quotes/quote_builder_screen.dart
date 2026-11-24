import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feature_flags.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/submit_action.dart';
import '../../core/utils/bill_totals.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/quotes_repository.dart';
import '../../domain/models/order_item.dart';
import '../auth/providers/auth_provider.dart';
import '../orders/providers.dart';

class _DraftLine {
  _DraftLine({
    required this.productId,
    required this.name,
    required this.qty,
    required this.rate,
    this.usedLastQuoted = false,
  }) : discount = 0,
       rateController = TextEditingController(text: formatNpr(Paisa(rate))),
       discountController = TextEditingController(),
       rateFocus = FocusNode(debugLabel: 'quoteRate'),
       discountFocus = FocusNode(debugLabel: 'quoteDiscount') {
    rateFocus.addListener(_onRateFocus);
    discountFocus.addListener(_onDiscountFocus);
  }

  final String productId;
  final String name;
  final bool usedLastQuoted;
  int qty;
  int rate;
  int discount;
  final TextEditingController rateController;
  final TextEditingController discountController;
  final FocusNode rateFocus;
  final FocusNode discountFocus;

  void _selectAll(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _onRateFocus() {
    if (rateFocus.hasFocus) _selectAll(rateController);
  }

  void _onDiscountFocus() {
    if (discountFocus.hasFocus) _selectAll(discountController);
  }

  int get lineTotal =>
      lineTotalPaisa(qty: qty, ratePaisa: rate, discountPaisa: discount);

  int? get tryLineTotal =>
      tryLineTotalPaisa(qty: qty, ratePaisa: rate, discountPaisa: discount);

  bool get discountValid =>
      isValidLineDiscount(qty: qty, ratePaisa: rate, discountPaisa: discount);

  void dispose() {
    rateFocus.removeListener(_onRateFocus);
    discountFocus.removeListener(_onDiscountFocus);
    rateFocus.dispose();
    discountFocus.dispose();
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
  ConsumerState<QuoteBuilderScreen> createState() => QuoteBuilderScreenState();
}

class QuoteBuilderScreenState extends ConsumerState<QuoteBuilderScreen> {
  final _lines = <_DraftLine>[];
  bool _loading = false;
  bool _initialized = false;
  bool _draftLoading = true;
  Object? _draftError;
  final _formKey = GlobalKey<FormState>();

  int get _total => itemsTotalPaisa(_lines.map((l) => l.lineTotal));

  int get _totalDiscount =>
      lineDiscountsTotalPaisa(_lines.map((l) => l.discount));

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

  Future<void> sendQuote() => _sendQuote();

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
        final usedLastQuoted = lastQuoted != null && lastQuoted > 0;
        loaded.add(
          _DraftLine(
            productId: item.productId,
            name: item.productName ?? product.name,
            qty: item.qty,
            rate: resolveQuoteRate(
              lastQuotedPaisa: lastQuoted,
              referencePaisa: product.referencePrice,
            ),
            usedLastQuoted: usedLastQuoted,
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

  TextStyle? _moneyStyle(TextStyle? base) => kIsWeb
      ? base?.copyWith(
          fontFamily: 'IBM Plex Mono',
          fontFamilyFallback: const ['Inter', 'Noto Sans Devanagari'],
        )
      : base?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  Widget _buildLineCard(
    BuildContext context,
    AppLocalizations l10n,
    int index,
  ) {
    final line = _lines[index];
    final hasNext = index + 1 < _lines.length;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final rateField = TextFormField(
      controller: line.rateController,
      focusNode: line.rateFocus,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => line.discountFocus.requestFocus(),
      validator: (value) {
        final parsed = parseNpr(value ?? '');
        if (parsed == null || parsed.value < 0) {
          return l10n.invalidNumber;
        }
        if (tryLineGrossPaisa(qty: line.qty, ratePaisa: parsed.value) == null) {
          return l10n.invalidNumber;
        }
        return null;
      },
      decoration: InputDecoration(
        isDense: true,
        labelText: l10n.rate,
        errorText: line.tryLineTotal == null ? l10n.invalidNumber : null,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => setState(() {
        line.rate = parseNpr(v)?.value ?? line.rate;
      }),
    );

    final discountField = TextFormField(
      controller: line.discountController,
      focusNode: line.discountFocus,
      textInputAction: hasNext ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (hasNext) {
          _lines[index + 1].rateFocus.requestFocus();
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      validator: (value) {
        final parsed = parseNpr(value == null || value.isEmpty ? '0' : value);
        if (parsed == null || parsed.value < 0) {
          return l10n.invalidNumber;
        }
        final gross = tryLineGrossPaisa(qty: line.qty, ratePaisa: line.rate);
        if (gross == null) return l10n.invalidNumber;
        return parsed.value > gross ? l10n.discountExceedsLine : null;
      },
      decoration: InputDecoration(
        isDense: true,
        labelText: l10n.lineDiscount,
        hintText: '0',
        errorText: line.tryLineTotal == null
            ? l10n.invalidNumber
            : line.discountValid
            ? null
            : l10n.discountExceedsLine,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => setState(() {
        line.discount = parseNpr(v)?.value ?? 0;
      }),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth >= 460;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        line.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (line.usedLastQuoted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(BsRadii.full),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          l10n.lastQuotedRate,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (line.rate == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Chip(
                      avatar: const Icon(
                        Icons.warning_amber_outlined,
                        size: 18,
                      ),
                      label: Text(l10n.rateMissing),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.quantity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    QtyStepper(
                      value: line.qty,
                      min: 1,
                      compact: true,
                      onChanged: (v) => setState(() => line.qty = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (sideBySide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: rateField),
                      const SizedBox(width: 12),
                      Expanded(child: discountField),
                    ],
                  )
                else ...[
                  rateField,
                  const SizedBox(height: 10),
                  discountField,
                ],
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (line.discount > 0 && line.tryLineTotal != null)
                      Text(
                        '${l10n.discount}: -${formatNpr(Paisa(line.discount), showPaisa: true)}',
                        style: _moneyStyle(
                          theme.textTheme.bodySmall?.copyWith(
                            color: BsColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${l10n.lineTotal}: ${line.tryLineTotal == null ? l10n.invalidNumber : formatNpr(Paisa(line.tryLineTotal!))}',
                        style: _moneyStyle(
                          theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: line.tryLineTotal == null
                                ? scheme.error
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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

        final totalDiscount = _totalDiscount;
        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _lines.length,
                      itemBuilder: (context, index) =>
                          _buildLineCard(context, l10n, index),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (totalDiscount > 0) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.totalDiscount,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: BsColors.success),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '- ${formatNpr(Paisa(totalDiscount), showPaisa: true)}',
                                    style: _moneyStyle(
                                      theme.textTheme.bodySmall?.copyWith(
                                        color: BsColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              '${l10n.grandTotal}: ${_tryTotal == null ? l10n.invalidNumber : formatNpr(Paisa(_tryTotal!))}',
                              style: _moneyStyle(
                                theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _tryTotal == null
                                      ? scheme.error
                                      : scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed: _loading || _lines.isEmpty
                                  ? null
                                  : _sendQuote,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(l10n.sendQuote),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
