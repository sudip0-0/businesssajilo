import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/list_skeleton.dart';
import '../../core/ui/submit_action.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/stock_reconciliation_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/product.dart';
import '../auth/providers/auth_provider.dart';
import 'providers.dart';
import 'stock_count_controller.dart';

/// Multi-product physical stock count & reconciliation screen (Owner & Warehouse).
///
/// Strictly displays product identity and stock quantities only — zero cost,
/// selling price, valuation, or customer financial fields.
class StockCountScreen extends ConsumerStatefulWidget {
  const StockCountScreen({super.key});

  @override
  ConsumerState<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends ConsumerState<StockCountScreen> {
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
        backgroundColor: BsColors.danger,
      );
      return;
    }
    if (_draft.hasAnyInvalid(_products)) {
      showBsSnackBar(
        context,
        message: l10n.stockCountInvalidQty,
        backgroundColor: BsColors.danger,
      );
      return;
    }
    final payload = _draft.buildPayload(_products);
    if (payload.isEmpty) {
      showBsSnackBar(
        context,
        message: l10n.stockCountNoChanges,
        backgroundColor: BsColors.danger,
      );
      return;
    }
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      showBsSnackBar(
        context,
        message: l10n.reasonRequired,
        backgroundColor: BsColors.danger,
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
      return Scaffold(
        appBar: AppBar(title: Text(l10n.stockCount)),
        body: EmptyState(
          icon: Icons.lock_outline,
          message: l10n.errorPermission,
        ),
      );
    }

    final counted = _draft.countedEntries(_products);
    final changed = _draft.changedEntries(_products);
    final net = _draft.netVariance(_products);
    final hasInvalid = _draft.hasAnyInvalid(_products);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockCount)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.stockCountSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: BsColors.outline),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.filterProducts,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: Text(l10n.stockCountChangedOnly),
                      selected: _changedOnly,
                      onSelected: (v) => setState(() => _changedOnly = v),
                    ),
                    Text(
                      l10n.stockCountSummary(counted.length, changed.length),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: BsColors.outline,
                      ),
                    ),
                    if (changed.isNotEmpty)
                      Text(
                        l10n.stockCountNetVariance(formatSignedVariance(net)),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: net >= 0
                                  ? BsColors.success
                                  : BsColors.danger,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(l10n)),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: l10n.adjustmentReason,
                      hintText: l10n.stockCountReasonHint,
                    ),
                    maxLength: 300,
                    maxLines: 1,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
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
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fact_check_outlined),
                    label: Text(
                      changed.isEmpty
                          ? l10n.stockCountSubmit
                          : '${l10n.stockCountSubmit} (${changed.length})',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loadingProducts) {
      return const ListSkeleton();
    }
    if (_loadError != null) {
      return ErrorState(message: l10n.loadingFailed, onRetry: _loadProducts);
    }
    final items = _visibleProducts;
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        message: _products.isEmpty
            ? l10n.emptyNoProducts
            : l10n.noMatchingResults,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = items[index];
        final controller = _controllerFor(product.id);
        final invalid = _draft.isInvalid(product.id);
        final parsed = _draft.parsedCountFor(product.id);
        final delta = parsed == null ? null : parsed - product.stockCached;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (product.sku != null && product.sku!.isNotEmpty)
                          product.sku!,
                        '${l10n.systemStock}: ${product.stockCached} ${product.unit}',
                      ].join(' · '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: BsColors.outline),
                    ),
                    if (invalid)
                      Text(
                        l10n.stockCountInvalidQty,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: BsColors.danger,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: l10n.countedStock,
                    isDense: true,
                    errorText: invalid ? '' : null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                  onChanged: (value) {
                    setState(() => _draft.setRawInput(product.id, value));
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 56, child: _VarianceBadge(delta: delta)),
            ],
          ),
        );
      },
    );
  }
}

class _VarianceBadge extends StatelessWidget {
  const _VarianceBadge({required this.delta});

  final int? delta;

  @override
  Widget build(BuildContext context) {
    if (delta == null) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: BsColors.outline),
      );
    }
    final color = delta == 0
        ? BsColors.outline
        : (delta! > 0 ? BsColors.success : BsColors.danger);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BsRadii.sm),
      ),
      child: Text(
        formatSignedVariance(delta!),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
