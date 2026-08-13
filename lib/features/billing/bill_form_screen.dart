import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/ui/bs_success_button.dart';
import '../../core/ui/error_state.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/product.dart';
import '../inventory/providers.dart';
import 'bill_form_draft.dart';
import 'bill_form_line_editor.dart';
import 'bill_form_product_picker.dart';
import 'bill_form_submit.dart';
import 'bill_summary.dart';
import 'copy_last_bill.dart';

class BillFormScreen extends ConsumerStatefulWidget {
  const BillFormScreen({super.key, this.embedded = false, this.onSaved});

  final bool embedded;
  final VoidCallback? onSaved;

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final _draft = BillFormDraft();
  final _billDiscountController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounceTimer;
  String _query = '';

  /// Last loaded products stay on screen while the next query is in flight,
  /// so the search field is never unmounted mid-typing. Only reused when
  /// [_lastProductsQuery] still matches the typed text.
  List<Product> _lastProducts = const [];
  String _lastProductsQuery = '';
  bool _productsLoadedOnce = false;
  bool _loading = false;

  /// On narrow screens, show cart review after the first line is added.
  bool _showCart = false;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _billDiscountController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _copyLastBill() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final bill = await fetchLatestBillWithItems(
        ref.read(billsRepositoryProvider),
      );
      if (!mounted) return;
      if (bill == null) {
        showBsSnackBar(context, message: l10n.noBillsToCopy);
        return;
      }
      final catalog = await productsForBillItems(
        products: ref.read(productsRepositoryProvider),
        bill: bill,
      );
      if (!mounted) return;
      setState(() {
        _draft.loadFromBill(bill, catalog);
        _billDiscountController.text = _draft.billDiscountText;
        _showCart = _draft.lines.isNotEmpty;
      });
      if (_draft.lines.isEmpty) {
        showBsSnackBar(context, message: l10n.noBillLines);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncDiscountText() {
    _draft.billDiscountText = _billDiscountController.text;
  }

  void _onQueryChanged(String raw) {
    _searchDebounceTimer?.cancel();
    final query = raw.trim();
    // Rebuild immediately so the picker drops stale catalog rows.
    setState(() {});
    if (query == _query) return;
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (mounted) setState(() => _query = query);
    });
  }

  void _addProduct(Product product) {
    setState(() {
      _draft.addProduct(product);
      _showCart = true;
    });
  }

  Future<Bill?> _save({bool exportAfterSave = false}) async {
    _syncDiscountText();
    setState(() => _loading = true);
    final bill = await submitBillForm(
      ref: ref,
      context: context,
      draft: _draft,
      exportAfterSave: exportAfterSave,
      onSaved: widget.onSaved,
      popOnSuccess: widget.onSaved == null && !widget.embedded,
    );
    if (mounted) setState(() => _loading = false);
    return bill;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(productListProvider(_query), (_, next) {
      final value = next.value;
      if (value != null) {
        setState(() {
          _lastProducts = value;
          _lastProductsQuery = _query;
          _productsLoadedOnce = true;
        });
      }
    });

    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(productListProvider(_query));
    final liveQuery = _searchController.text.trim();
    final products = liveQuery == _lastProductsQuery
        ? (productsAsync.value ?? _lastProducts)
        : const <Product>[];
    final firstLoad = productsAsync.isLoading && !_productsLoadedOnce;
    final loadFailed = productsAsync.hasError && !_productsLoadedOnce;
    final refreshing =
        (liveQuery.isNotEmpty && liveQuery != _lastProductsQuery) ||
        (liveQuery == _query && productsAsync.isLoading && _productsLoadedOnce);

    final Widget body;
    if (firstLoad) {
      body = const Center(child: CircularProgressIndicator());
    } else if (loadFailed) {
      body = ErrorState(
        message: l10n.loadingFailed,
        onRetry: () => ref.invalidate(productListProvider(_query)),
      );
    } else {
      body = _buildBody(l10n, products, refreshing);
    }

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createNewBill),
        actions: [
          TextButton(
            onPressed: _loading ? null : _copyLastBill,
            child: Text(l10n.copyLastBill),
          ),
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BsSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BsSuccessButton(
                loading: _loading,
                onPressed: () {
                  final narrow = MediaQuery.sizeOf(context).width < 720;
                  if (narrow && !_showCart && _draft.lines.isNotEmpty) {
                    setState(() => _showCart = true);
                    return;
                  }
                  _save();
                },
                label: l10n.saveBill,
              ),
              if (_draft.lines.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _save(exportAfterSave: true),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(l10n.printAndSave),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    List<Product> products,
    bool refreshing,
  ) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final showPicker = !narrow || !_showCart || _draft.lines.isEmpty;
    final showCart = !narrow || _showCart;

    Widget productPicker() => BillFormProductPicker(
      products: products,
      controller: _searchController,
      focusNode: _searchFocus,
      refreshing: refreshing,
      onQueryChanged: _onQueryChanged,
      onProductSelected: _addProduct,
    );

    Widget cartPane() => Column(
      children: [
        if (narrow && _draft.lines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BsSpacing.sm,
              BsSpacing.xs,
              BsSpacing.sm,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showCart = false),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addProduct),
              ),
            ),
          ),
        Expanded(
          child: _draft.lines.isEmpty
              ? Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showCart = false),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.noBillLines),
                  ),
                )
              : ListView.builder(
                  itemCount: _draft.lines.length,
                  itemBuilder: (context, index) {
                    final line = _draft.lines[index];
                    return BillFormLineEditor(
                      line: line,
                      onChanged: () => setState(() {}),
                      onRemove: () => setState(() {
                        _draft.removeLineAt(index);
                        if (_draft.lines.isEmpty) _showCart = false;
                      }),
                    );
                  },
                ),
        ),
        BillSummary(
          itemsTotal: _draft.itemsTotal,
          billDiscountController: _billDiscountController,
          grandTotal: _draft.grandTotal,
          onDiscountChanged: () {
            _syncDiscountText();
            setState(() {});
          },
        ),
      ],
    );

    if (narrow) {
      return Column(
        children: [
          Expanded(child: showPicker ? productPicker() : cartPane()),
          if (widget.embedded)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(BsSpacing.lg),
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (showPicker && _draft.lines.isNotEmpty) {
                            setState(() => _showCart = true);
                            return;
                          }
                          _save();
                        },
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          showPicker && _draft.lines.isNotEmpty
                              ? l10n.reviewAndSave
                              : l10n.saveBill,
                        ),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(flex: _draft.lines.isEmpty ? 1 : 2, child: productPicker()),
        const Divider(height: 1),
        Expanded(
          flex: _draft.lines.isEmpty ? 0 : 3,
          child: showCart ? cartPane() : const SizedBox.shrink(),
        ),
        if (widget.embedded)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(BsSpacing.lg),
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveBill),
              ),
            ),
          ),
      ],
    );
  }
}
