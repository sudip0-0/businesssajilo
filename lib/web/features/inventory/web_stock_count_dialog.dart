import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/bs_snackbar.dart';
import '../../../core/ui/submit_action.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/stock_reconciliation_repository.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/product.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/inventory/providers.dart';
import '../../../features/inventory/stock_count_controller.dart';
import '../../theme/web_palette.dart';
import '../../theme/web_typography.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_search_field.dart';
import '../../ui/web_skeleton.dart';

/// Opens the Digital Ledger stock count / reconciliation modal on web.
Future<bool?> showWebStockCountDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: const WebStockCountDialog(),
      ),
    ),
  );
}

/// Digital Ledger styled physical stock count modal (Owner & Warehouse only).
///
/// Strictly displays product identity and quantities only — zero cost, selling
/// price, valuation, or customer financial fields.
class WebStockCountDialog extends ConsumerStatefulWidget {
  const WebStockCountDialog({super.key});

  @override
  ConsumerState<WebStockCountDialog> createState() =>
      _WebStockCountDialogState();
}

class _WebStockCountDialogState extends ConsumerState<WebStockCountDialog> {
  final _draft = StockCountDraft();
  final _reasonController = TextEditingController();
  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};

  List<Product> _products = const [];
  bool _loadingProducts = true;
  Object? _loadError;
  bool _submitting = false;
  bool _changedOnly = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(_draft.onReasonEdited);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _searchController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
      _loadError = null;
    });
    try {
      final items = await ref
          .read(productsRepositoryProvider)
          .list(activeOnly: true, limit: 500);
      if (!mounted) return;
      setState(() {
        _products = items;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loadingProducts = false;
      });
    }
  }

  TextEditingController _controllerFor(String productId) {
    return _qtyControllers.putIfAbsent(
      productId,
      () => TextEditingController(text: _draft.rawInputFor(productId)),
    );
  }

  List<Product> get _visibleProducts {
    final q = _query.trim().toLowerCase();
    return _products.where((p) {
      if (_changedOnly) {
        final parsed = _draft.parsedCountFor(p.id);
        final invalid = _draft.isInvalid(p.id);
        if (!invalid && (parsed == null || parsed == p.stockCached)) {
          return false;
        }
      }
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.nameNp?.toLowerCase().contains(q) ?? false) ||
          (p.sku?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context);
    final member = ref.read(authProvider).value?.member;
    if (member == null || !member.role.canManageStock) {
      showBsSnackBar(
        context,
        message: l10n.errorPermission,
        backgroundColor: WebPalette.danger,
      );
      return;
    }
    if (_draft.hasAnyInvalid(_products)) {
      showBsSnackBar(
        context,
        message: l10n.stockCountInvalidQty,
        backgroundColor: WebPalette.danger,
      );
      return;
    }
    final payload = _draft.buildPayload(_products);
    if (payload.isEmpty) {
      showBsSnackBar(
        context,
        message: l10n.stockCountNoChanges,
        backgroundColor: WebPalette.danger,
      );
      return;
    }
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      showBsSnackBar(
        context,
        message: l10n.reasonRequired,
        backgroundColor: WebPalette.danger,
      );
      return;
    }

    setState(() => _submitting = true);
    _draft.markAttemptStarted();
    await runSubmitAction(
      context,
      action: () async {
        final result = await ref
            .read(stockReconciliationRepositoryProvider)
            .reconcileStockCount(
              opId: _draft.opId,
              reason: reason,
              items: payload,
              createdByMemberId: member.id,
            );
        bumpInventoryRevision(ref);
        ref.invalidate(lowStockCountProvider);
        ref.invalidate(lowStockProductsProvider);
        ref.invalidate(lowStockAlertsProvider);
        if (!mounted) return;
        showBsSnackBar(
          context,
          message: l10n.stockCountSuccess(result.adjustedCount),
        );
        Navigator.of(context).pop(true);
      },
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(authProvider.select((s) => s.value?.member?.role));
    if (role != null && !role.canManageStock) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: WebEmptyState(
          message: l10n.errorPermission,
          icon: PhosphorIconsRegular.lock,
        ),
      );
    }

    final counted = _draft.countedEntries(_products);
    final changed = _draft.changedEntries(_products);
    final net = _draft.netVariance(_products);
    final hasInvalid = _draft.hasAnyInvalid(_products);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: WebPalette.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: WebPalette.paper,
                border: Border(bottom: BorderSide(color: WebPalette.hairline)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: WebPalette.navy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.clipboardText,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.stockCount,
                          style: WebTypography.serif(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: WebPalette.ink,
                          ),
                        ),
                        Text(
                          l10n.stockCountSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: WebPalette.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.cancel,
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(PhosphorIconsRegular.x),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: WebSearchField(
                      hint: l10n.filterProducts,
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  FilterChip(
                    label: Text(l10n.stockCountChangedOnly),
                    selected: _changedOnly,
                    onSelected: (v) => setState(() => _changedOnly = v),
                  ),
                  Text(
                    l10n.stockCountSummary(counted.length, changed.length),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: WebPalette.inkSoft),
                  ),
                  if (changed.isNotEmpty)
                    Text(
                      l10n.stockCountNetVariance(formatSignedVariance(net)),
                      style: WebTypography.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: net >= 0
                            ? WebPalette.success
                            : WebPalette.danger,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: const BoxDecoration(
                color: WebPalette.paperDeep,
                border: Border.symmetric(
                  horizontal: BorderSide(color: WebPalette.hairline),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      l10n.productsTracked,
                      style: WebTypography.eyebrow(color: WebPalette.inkSoft),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: Text(
                      l10n.systemStock,
                      textAlign: TextAlign.right,
                      style: WebTypography.eyebrow(color: WebPalette.inkSoft),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 112,
                    child: Text(
                      l10n.countedStock,
                      textAlign: TextAlign.center,
                      style: WebTypography.eyebrow(color: WebPalette.inkSoft),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Text(
                      l10n.variance,
                      textAlign: TextAlign.right,
                      style: WebTypography.eyebrow(color: WebPalette.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildTableBody(l10n)),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: WebPalette.paper,
                border: Border(top: BorderSide(color: WebPalette.hairline)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 540;
                  final reasonField = TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: l10n.adjustmentReason,
                      hintText: l10n.stockCountReasonHint,
                      isDense: true,
                    ),
                    maxLength: 300,
                    onChanged: (_) => setState(() {}),
                  );
                  final actionsRow = Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed:
                            _submitting ||
                                hasInvalid ||
                                changed.isEmpty ||
                                _reasonController.text.trim().isEmpty
                            ? null
                            : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                PhosphorIconsRegular.checkCircle,
                                size: 18,
                              ),
                        label: Text(
                          changed.isEmpty
                              ? l10n.stockCountSubmit
                              : '${l10n.stockCountSubmit} (${changed.length})',
                        ),
                      ),
                    ],
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        reasonField,
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: actionsRow,
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: reasonField),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: actionsRow,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableBody(AppLocalizations l10n) {
    if (_loadingProducts) return const WebListSkeleton();
    if (_loadError != null) {
      return WebEmptyState(
        message: l10n.loadingFailed,
        actionLabel: l10n.tryAgain,
        onAction: _loadProducts,
        icon: PhosphorIconsRegular.warning,
      );
    }
    final items = _visibleProducts;
    if (items.isEmpty) {
      return WebEmptyState(
        message: _products.isEmpty
            ? l10n.emptyNoProducts
            : l10n.noMatchingResults,
        icon: PhosphorIconsRegular.package,
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: WebPalette.hairline),
      itemBuilder: (context, index) {
        final product = items[index];
        final controller = _controllerFor(product.id);
        final invalid = _draft.isInvalid(product.id);
        final parsed = _draft.parsedCountFor(product.id);
        final delta = parsed == null ? null : parsed - product.stockCached;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        if (product.sku != null && product.sku!.isNotEmpty)
                          product.sku!,
                        product.unit,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WebPalette.inkSoft,
                      ),
                    ),
                    if (invalid)
                      Text(
                        l10n.stockCountInvalidQty,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: WebPalette.danger,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                child: Text(
                  '${product.stockCached}',
                  textAlign: TextAlign.right,
                  style: WebTypography.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: WebPalette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 112,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: WebTypography.mono(
                    fontSize: 13,
                    color: WebPalette.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: '${product.stockCached}',
                    isDense: true,
                    errorText: invalid ? '' : null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                  onChanged: (value) {
                    setState(() => _draft.setRawInput(product.id, value));
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: Text(
                  delta == null ? '—' : formatSignedVariance(delta),
                  textAlign: TextAlign.right,
                  style: WebTypography.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: delta == null || delta == 0
                        ? WebPalette.inkSoft
                        : (delta > 0 ? WebPalette.success : WebPalette.danger),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
