import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/paginated_list_state.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/submit_action.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../domain/models/product.dart';
import '../auth/providers/auth_provider.dart';
import 'providers.dart';

/// Multi-select stock-in: pick several products, set a quantity for each, and
/// record all movements in one pass (warehouse restock).
class StockInPickerSheet extends ConsumerStatefulWidget {
  const StockInPickerSheet({super.key});

  @override
  ConsumerState<StockInPickerSheet> createState() => _StockInPickerSheetState();
}

class _StockInPickerSheetState extends ConsumerState<StockInPickerSheet> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final Set<String> _selected = {};
  final Map<String, int> _qtys = {};
  final Map<String, String> _names = {};
  bool _enteringQty = false;
  bool _loading = false;

  String _query = '';
  Timer? _searchDebounceTimer;
  PaginatedListState<Product>? _pager;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPager());
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _initPager() {
    _pager = PaginatedListState<Product>(
      loadPage: (offset, limit) => ref
          .read(productsRepositoryProvider)
          .list(
            offset: offset,
            limit: limit,
            query: _query.trim().isEmpty ? null : _query.trim(),
          ),
      onChanged: () {
        if (mounted) setState(() {});
      },
    )..attachScrollController(_scrollController);
    _pager!.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onQueryChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _pager?.refresh();
    });
  }

  void _toggle(Product product) {
    setState(() {
      if (_selected.contains(product.id)) {
        _selected.remove(product.id);
        _qtys.remove(product.id);
        _names.remove(product.id);
      } else {
        _selected.add(product.id);
        _qtys[product.id] = 1;
        _names[product.id] = product.name;
      }
    });
  }

  Future<void> _save() async {
    final memberId = ref.read(authProvider).value?.member?.id;
    if (memberId == null) return;
    setState(() => _loading = true);
    await runSubmitAction(
      context,
      action: () async {
        final repo = ref.read(stockRepositoryProvider);
        for (final productId in _selected) {
          await repo.stockIn(
            productId: productId,
            qty: _qtys[productId] ?? 1,
            createdByMemberId: memberId,
          );
        }
        ref.invalidate(productListProvider);
        ref.invalidate(lowStockCountProvider);
        bumpInventoryRevision(ref);
        if (mounted) Navigator.pop(context, true);
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pager = _pager;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, _) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.stockIn,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (_enteringQty)
              _buildQtyPanel(l10n)
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchProductsHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: _onQueryChanged,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildProductList(l10n, pager)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => setState(() => _enteringQty = true),
                    icon: const Icon(Icons.add_box_outlined),
                    label: Text('${l10n.stockIn} (${_selected.length})'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(
    AppLocalizations l10n,
    PaginatedListState<Product>? pager,
  ) {
    if (pager == null || pager.initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pager.error != null && pager.items.isEmpty) {
      return ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => pager.refresh(),
      );
    }
    if (pager.items.isEmpty) {
      return Center(child: Text(l10n.noMatchingResults));
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: pager.items.length + (pager.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= pager.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final product = pager.items[index];
        final selected = _selected.contains(product.id);
        return CheckboxListTile(
          value: selected,
          onChanged: (_) => _toggle(product),
          title: Text(product.name),
          subtitle: Text('${product.stockCached} ${product.unit}'),
          secondary: Icon(
            selected ? Icons.check_box : Icons.check_box_outline_blank,
          ),
        );
      },
    );
  }

  Widget _buildQtyPanel(AppLocalizations l10n) {
    final selectedProducts = _selected.toList();
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _enteringQty = false),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(l10n.products),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final productId in selectedProducts)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _names[productId] ?? productId,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        QtyStepper(
                          value: _qtys[productId] ?? 1,
                          min: 1,
                          onChanged: (v) =>
                              setState(() => _qtys[productId] = v),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
