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
import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/product.dart';
import '../inventory/providers.dart';
import 'bill_form_draft.dart';
import 'bill_form_leave_confirm.dart';
import 'bill_form_line_editor.dart';
import 'bill_form_product_picker.dart';
import 'bill_form_submit.dart';
import 'bill_summary.dart';
import 'copy_last_bill.dart';
import 'providers.dart';

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

  bool get _isDirty =>
      _draft.lines.isNotEmpty ||
      _draft.customerId != null ||
      (_draft.guestName?.trim().isNotEmpty ?? false) ||
      _draft.billDiscount != 0;

  void _syncDirtyFlag() {
    ref.read(billFormDirtyProvider.notifier).setDirty(_isDirty);
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
      _syncDirtyFlag();
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
    _syncDirtyFlag();
  }

  Future<Bill?> _save({
    bool exportAfterSave = false,
    BillStatus? forceStatus,
  }) async {
    _syncDiscountText();
    setState(() => _loading = true);
    final bill = await submitBillForm(
      ref: ref,
      context: context,
      draft: _draft,
      forceStatus: forceStatus,
      exportAfterSave: exportAfterSave,
      onSaved: () {
        ref.read(billFormDirtyProvider.notifier).clear();
        widget.onSaved?.call();
      },
      popOnSuccess: widget.onSaved == null && !widget.embedded,
    );
    if (mounted) setState(() => _loading = false);
    return bill;
  }

  Future<void> _onWillPop() async {
    if (!_isDirty) {
      ref.read(billFormDirtyProvider.notifier).clear();
      return;
    }
    final leave = await confirmLeaveUnsavedBill(context);
    if (leave && mounted) {
      ref.read(billFormDirtyProvider.notifier).clear();
      Navigator.of(context).pop();
    }
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
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          ref.read(billFormDirtyProvider.notifier).clear();
          return;
        }
        await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.createNewBill,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: l10n.more,
              onSelected: (value) {
                if (value == 'copy') _copyLastBill();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: !_loading,
                  value: 'copy',
                  child: Text(l10n.copyLastBill),
                ),
              ],
            ),
          ],
        ),
        body: body,
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BsSpacing.lg,
              4,
              BsSpacing.lg,
              BsSpacing.sm,
            ),
            child: _SaveActionBar(
              loading: _loading,
              showSaveAsDue: true,
              showPrint: _draft.lines.isNotEmpty,
              primaryLabel: l10n.saveBill,
              onSaveAsDue: () => _save(forceStatus: BillStatus.due),
              onPrimary: () {
                final narrow = MediaQuery.sizeOf(context).width < 720;
                if (narrow && !_showCart && _draft.lines.isNotEmpty) {
                  setState(() => _showCart = true);
                  return;
                }
                _save();
              },
              onPrintAndSave: () => _save(exportAfterSave: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _embeddedSaveBar({
    required VoidCallback onPrimary,
    required String primaryLabel,
    bool showSaveAsDue = true,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BsSpacing.lg,
          4,
          BsSpacing.lg,
          BsSpacing.sm,
        ),
        child: _SaveActionBar(
          loading: _loading,
          showSaveAsDue: showSaveAsDue,
          showPrint: false,
          primaryLabel: primaryLabel,
          onSaveAsDue: () => _save(forceStatus: BillStatus.due),
          onPrimary: onPrimary,
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
                      onChanged: () {
                        setState(() {});
                        _syncDirtyFlag();
                      },
                      onRemove: () {
                        setState(() {
                          _draft.removeLineAt(index);
                          if (_draft.lines.isEmpty) _showCart = false;
                        });
                        _syncDirtyFlag();
                      },
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
            _syncDirtyFlag();
          },
        ),
      ],
    );

    if (narrow) {
      return Column(
        children: [
          Expanded(child: showPicker ? productPicker() : cartPane()),
          if (widget.embedded)
            _embeddedSaveBar(
              showSaveAsDue: !(showPicker && _draft.lines.isNotEmpty),
              onPrimary: () {
                if (showPicker && _draft.lines.isNotEmpty) {
                  setState(() => _showCart = true);
                  return;
                }
                _save();
              },
              primaryLabel: showPicker && _draft.lines.isNotEmpty
                  ? l10n.reviewAndSave
                  : l10n.saveBill,
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
          _embeddedSaveBar(
            onPrimary: () => _save(),
            primaryLabel: l10n.saveBill,
          ),
      ],
    );
  }
}

class _SaveActionBar extends StatelessWidget {
  const _SaveActionBar({
    required this.loading,
    required this.showSaveAsDue,
    required this.showPrint,
    required this.primaryLabel,
    required this.onSaveAsDue,
    required this.onPrimary,
    this.onPrintAndSave,
  });

  final bool loading;
  final bool showSaveAsDue;
  final bool showPrint;
  final String primaryLabel;
  final VoidCallback onSaveAsDue;
  final VoidCallback onPrimary;
  final VoidCallback? onPrintAndSave;

  static const _compactSize = Size(0, 40);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outlinedStyle = OutlinedButton.styleFrom(
      minimumSize: _compactSize,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    final textStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSaveAsDue)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: outlinedStyle,
                  onPressed: loading ? null : onSaveAsDue,
                  child: Text(
                    l10n.saveAsDue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        minimumSize: _compactSize,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  child: BsSuccessButton(
                    loading: loading,
                    onPressed: onPrimary,
                    label: primaryLabel,
                  ),
                ),
              ),
            ],
          )
        else
          Theme(
            data: Theme.of(context).copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  minimumSize: _compactSize,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            child: BsSuccessButton(
              loading: loading,
              onPressed: onPrimary,
              label: primaryLabel,
            ),
          ),
        if (showPrint && onPrintAndSave != null)
          TextButton.icon(
            style: textStyle,
            onPressed: loading ? null : onPrintAndSave,
            icon: const Icon(Icons.print_outlined, size: 16),
            label: Text(l10n.printAndSave),
          ),
      ],
    );
  }
}
