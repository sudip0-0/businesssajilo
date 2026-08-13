import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/layout/bs_breakpoints.dart';
import '../../../core/testing/integration_keys.dart';
import '../../../core/ui/bs_snackbar.dart';
import '../../../core/ui/stock_badge.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/bills_repository.dart';
import '../../../data/repositories/customers_repository.dart';
import '../../../data/repositories/orders_repository.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/bill.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/product.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/billing/bill_draft_line.dart';
import '../../../features/billing/bill_form_draft.dart';
import '../../../features/billing/bill_form_submit.dart';
import '../../../features/billing/bill_summary.dart';
import '../../../features/billing/providers.dart';
import '../../../features/customers/providers.dart';
import '../../../features/inventory/providers.dart';
import '../../layout/web_bento_grid.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_search_dropdown.dart';
import 'web_bill_form_line_table.dart';

/// POS-style bill form for web: product search + cart on the left, a sticky
/// checkout rail (customer, totals) on the right on wide screens.
///
/// Search inputs are debounced. Cached results are only shown when they still
/// match the typed query — otherwise the dropdown shows a loading state so the
/// empty-query catalog never flashes for a non-matching keystroke like "Z".
///
/// When [orderId] is set, the form prefills customer + lines from that order
/// and saving uses create-from-order (marks the order billed).
class WebBillFormContent extends ConsumerStatefulWidget {
  const WebBillFormContent({super.key, this.onSaved, this.orderId});

  final VoidCallback? onSaved;
  final String? orderId;

  @override
  ConsumerState<WebBillFormContent> createState() => WebBillFormContentState();
}

class WebBillFormContentState extends ConsumerState<WebBillFormContent> {
  static const _searchDebounce = Duration(milliseconds: 300);
  static const _railWidth = 360.0;

  final _draft = BillFormDraft(billDiscountText: '0');
  final _billDiscountController = TextEditingController(text: '0');
  final _productQueryController = TextEditingController();
  final _productSearchFocus = FocusNode();
  final _customerQueryController = TextEditingController();
  final _customerSearchFocus = FocusNode();
  final _guestNameController = TextEditingController();

  Timer? _productDebounce;
  Timer? _customerDebounce;
  String _productQuery = '';
  String _customerQuery = '';

  /// Last successfully loaded lists — kept on screen while the next query is
  /// in flight so the UI never flashes a loading state mid-typing. Only reused
  /// when [_lastProductsQuery] / [_lastCustomersQuery] still matches what the
  /// user has typed (avoids flashing the empty-query catalog for "Z").
  List<Product> _lastProducts = const [];
  List<Customer> _lastCustomers = const [];
  String _lastProductsQuery = '';
  String _lastCustomersQuery = '';

  Customer? _selectedCustomer;
  bool _loading = false;
  bool _orderPrefillLoading = false;
  bool _customerLocked = false;

  /// After adding a product, focus that line's qty field once.
  String? _focusQtyProductId;

  @override
  void initState() {
    super.initState();
    final orderId = widget.orderId;
    if (orderId != null && orderId.isNotEmpty) {
      _orderPrefillLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillFromOrder(orderId);
      });
    }
  }

  Future<void> _prefillFromOrder(String orderId) async {
    final l10n = AppLocalizations.of(context);
    try {
      final order = await ref.read(ordersRepositoryProvider).get(orderId);
      final customer = await ref
          .read(customersRepositoryProvider)
          .get(order.customerId);
      final productsRepo = ref.read(productsRepositoryProvider);
      final lines = <BillDraftLine>[];
      for (final item in order.items) {
        try {
          final product = await productsRepo.get(item.productId);
          lines.add(
            BillDraftLine(
              product: product,
              qty: item.qty,
              rate: product.referencePrice,
            ),
          );
        } catch (_) {
          // Skip deleted/missing products; keep remaining lines.
        }
      }
      if (!mounted) return;
      setState(() {
        _selectedCustomer = customer;
        _draft.customerId = customer.id;
        _customerLocked = true;
        _draft.lines
          ..clear()
          ..addAll(lines);
        _orderPrefillLoading = false;
      });
      _syncDirtyFlag();
      if (lines.isEmpty) {
        showBsSnackBar(context, message: l10n.noBillLines);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _orderPrefillLoading = false);
      showBsSnackBar(
        context,
        message: AppFailure.from(e).message(l10n),
        backgroundColor: WebPalette.danger,
      );
    }
  }

  @override
  void dispose() {
    _productDebounce?.cancel();
    _customerDebounce?.cancel();
    _billDiscountController.dispose();
    _productQueryController.dispose();
    _productSearchFocus.dispose();
    _customerQueryController.dispose();
    _customerSearchFocus.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  void _syncDraftFields() {
    _draft.billDiscountText = _billDiscountController.text;
    final guest = _guestNameController.text.trim();
    _draft.guestName = _selectedCustomer == null && guest.isNotEmpty
        ? guest
        : null;
  }

  bool get _isDirty =>
      _draft.lines.isNotEmpty ||
      _selectedCustomer != null ||
      _guestNameController.text.trim().isNotEmpty ||
      _draft.billDiscount != 0;

  void _syncDirtyFlag() {
    ref.read(billFormDirtyProvider.notifier).setDirty(_isDirty);
  }

  void focusProductSearch() {
    _productSearchFocus.requestFocus();
  }

  Future<void> copyLastBill() async {
    if (_customerLocked) return;
    final l10n = AppLocalizations.of(context);
    final bills = await ref.read(billsRepositoryProvider).list(limit: 1);
    if (!mounted) return;
    if (bills.isEmpty) {
      showBsSnackBar(context, message: l10n.noBillsToCopy);
      return;
    }
    var catalog = _lastProducts;
    if (catalog.isEmpty) {
      catalog = await ref.read(productListProvider('').future);
    }
    if (!mounted) return;
    setState(() {
      _draft.loadFromBill(bills.first, catalog);
    });
    _syncDirtyFlag();
  }

  void _onProductQueryChanged(String raw) {
    _productDebounce?.cancel();
    final query = raw.trim().toLowerCase();
    // Rebuild immediately so stale catalog rows are dropped before debounce.
    setState(() {});
    if (query == _productQuery) return;
    _productDebounce = Timer(_searchDebounce, () {
      if (mounted) setState(() => _productQuery = query);
    });
  }

  void _onCustomerQueryChanged(String raw) {
    _customerDebounce?.cancel();
    final query = raw.trim().toLowerCase();
    setState(() {});
    if (query == _customerQuery) return;
    _customerDebounce = Timer(_searchDebounce, () {
      if (mounted) setState(() => _customerQuery = query);
    });
  }

  void _addProduct(Product product) {
    _productDebounce?.cancel();
    setState(() {
      _draft.addProduct(product);
      _productQuery = '';
      _productQueryController.clear();
      _focusQtyProductId = product.id;
    });
    _syncDirtyFlag();
  }

  void _clearQtyFocusRequest() {
    _focusQtyProductId = null;
  }

  void _selectCustomer(Customer customer) {
    _customerDebounce?.cancel();
    setState(() {
      _selectedCustomer = customer;
      _draft.customerId = customer.id;
      _draft.guestName = null;
      _guestNameController.clear();
      _customerQuery = '';
      _customerQueryController.clear();
    });
    _syncDirtyFlag();
    focusProductSearch();
  }

  void _clearCustomer() {
    if (_customerLocked) return;
    setState(() {
      _selectedCustomer = null;
      _draft.customerId = null;
      _customerQuery = '';
      _customerQueryController.clear();
    });
    _syncDirtyFlag();
    _customerSearchFocus.requestFocus();
  }

  Future<void> saveDraft() => _save(forceStatus: BillStatus.due);

  Future<void> saveBill() => _save();

  Future<void> saveAndPrint() => _save(exportAfterSave: true);

  Future<Bill?> _save({
    BillStatus? forceStatus,
    bool exportAfterSave = false,
  }) async {
    _syncDraftFields();
    setState(() => _loading = true);
    final bill = await submitBillForm(
      ref: ref,
      context: context,
      draft: _draft,
      forceStatus: forceStatus,
      fallbackCustomerId: _draft.customerId,
      initialCustomerName: _selectedCustomer?.shopName,
      orderId: widget.orderId,
      exportAfterSave: exportAfterSave,
      onSaved: () {
        ref.read(billFormDirtyProvider.notifier).clear();
        widget.onSaved?.call();
      },
      snackbarErrorColor: WebPalette.danger,
    );
    if (mounted) setState(() => _loading = false);
    return bill;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(productListProvider(_productQuery), (_, next) {
      final value = next.value;
      if (value != null) {
        setState(() {
          _lastProducts = value;
          _lastProductsQuery = _productQuery;
        });
      }
    });
    ref.listen(customerListProvider(_customerQuery), (_, next) {
      final value = next.value;
      if (value != null) {
        setState(() {
          _lastCustomers = value;
          _lastCustomersQuery = _customerQuery;
        });
      }
    });

    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(productListProvider(_productQuery));
    final customersAsync = ref.watch(customerListProvider(_customerQuery));
    final liveProductQuery = _productQueryController.text.trim().toLowerCase();
    final liveCustomerQuery = _customerQueryController.text
        .trim()
        .toLowerCase();
    final products = liveProductQuery == _lastProductsQuery
        ? (productsAsync.value ?? _lastProducts)
        : const <Product>[];
    final customers = liveCustomerQuery == _lastCustomersQuery
        ? (customersAsync.value ?? _lastCustomers)
        : const <Customer>[];
    final productsLoading =
        (liveProductQuery.isNotEmpty &&
            liveProductQuery != _lastProductsQuery) ||
        (liveProductQuery == _productQuery && productsAsync.isLoading);
    final customersLoading =
        (liveCustomerQuery.isNotEmpty &&
            liveCustomerQuery != _lastCustomersQuery) ||
        (liveCustomerQuery == _customerQuery && customersAsync.isLoading);
    final today = DateFormat.yMMMd().format(DateTime.now());

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= BsBreakpoints.desktop;

            final cartCard = _CartCard(
              l10n: l10n,
              draft: _draft,
              productController: _productQueryController,
              productFocus: _productSearchFocus,
              products: products,
              productsLoading: productsLoading,
              productsFailed: productsAsync.hasError && products.isEmpty,
              onProductQueryChanged: _onProductQueryChanged,
              onProductSelected: _addProduct,
              onFocusProductSearch: focusProductSearch,
              focusQtyProductId: _focusQtyProductId,
              onQtyFocusHandled: _clearQtyFocusRequest,
              onLineChanged: () {
                setState(() {});
                _syncDirtyFlag();
              },
              onRemoveLine: (i) {
                setState(() => _draft.removeLineAt(i));
                _syncDirtyFlag();
              },
              scrollableLines: wide,
            );

            final rail = _CheckoutRail(
              l10n: l10n,
              today: today,
              selectedCustomer: _selectedCustomer,
              customerLocked: _customerLocked,
              customerController: _customerQueryController,
              customerFocus: _customerSearchFocus,
              guestNameController: _guestNameController,
              customers: customers,
              customersLoading: customersLoading,
              customersFailed: customersAsync.hasError && customers.isEmpty,
              onCustomerQueryChanged: _onCustomerQueryChanged,
              onCustomerSelected: _selectCustomer,
              onCustomerCleared: _clearCustomer,
              onGuestNameChanged: () {
                _syncDraftFields();
                _syncDirtyFlag();
              },
              itemsTotal: _draft.itemsTotal,
              billDiscountController: _billDiscountController,
              grandTotal: _draft.grandTotal,
              onDiscountChanged: () {
                _syncDraftFields();
                setState(() {});
                _syncDirtyFlag();
              },
              showCustomerBalance:
                  ref
                      .watch(authProvider)
                      .value
                      ?.member
                      ?.role
                      .canViewCustomerBalance ??
                  false,
            );

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cartCard),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: _railWidth,
                    child: SingleChildScrollView(child: rail),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [cartCard, const SizedBox(height: 16), rail],
              ),
            );
          },
        ),
        if (_loading || _orderPrefillLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),
      ],
    );
  }
}

/// Left pane: bill-lines header, editable cart lines, and product search below.
class _CartCard extends StatelessWidget {
  final AppLocalizations l10n;
  final BillFormDraft draft;
  final TextEditingController productController;
  final FocusNode productFocus;
  final List<Product> products;
  final bool productsLoading;
  final bool productsFailed;
  final ValueChanged<String> onProductQueryChanged;
  final ValueChanged<Product> onProductSelected;
  final VoidCallback onFocusProductSearch;
  final String? focusQtyProductId;
  final VoidCallback onQtyFocusHandled;
  final VoidCallback onLineChanged;
  final ValueChanged<int> onRemoveLine;

  /// True when the card is laid out with a bounded height (wide two-pane
  /// layout) and the lines area should scroll internally. False when the card
  /// lives inside a page-level scroll view (narrow stacked layout).
  final bool scrollableLines;

  const _CartCard({
    required this.l10n,
    required this.draft,
    required this.productController,
    required this.productFocus,
    required this.products,
    required this.productsLoading,
    required this.productsFailed,
    required this.onProductQueryChanged,
    required this.onProductSelected,
    required this.onFocusProductSearch,
    required this.focusQtyProductId,
    required this.onQtyFocusHandled,
    required this.onLineChanged,
    required this.onRemoveLine,
    required this.scrollableLines,
  });

  @override
  Widget build(BuildContext context) {
    final lines = draft.lines;
    final linesList = Column(
      children: [
        for (var i = 0; i < lines.length; i++)
          WebBillItemRow(
            key: ValueKey(lines[i].product.id),
            index: i,
            line: lines[i],
            l10n: l10n,
            onChanged: onLineChanged,
            onRemove: () => onRemoveLine(i),
            autofocusQty: focusQtyProductId == lines[i].product.id,
            onQtyFocusHandled: onQtyFocusHandled,
            onDoneEditing: onFocusProductSearch,
          ),
      ],
    );

    final productSearch = WebSearchDropdown<Product>(
      controller: productController,
      focusNode: productFocus,
      hint: l10n.filterProducts,
      items: products,
      loading: productsLoading,
      emptyLabel: productsFailed ? l10n.loadingFailed : l10n.noSearchResults,
      onQueryChanged: onProductQueryChanged,
      onSelected: onProductSelected,
      openOnFocus: false,
      refocusOnSelect: false,
      itemBuilder: _productTile,
    );

    final linesContent = LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 720.0;
        final tableWidth = constraints.maxWidth < minTableWidth
            ? minTableWidth
            : constraints.maxWidth;
        final table = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lines.isEmpty)
              _EmptyLinesHint(l10n: l10n)
            else ...[
              WebBillItemsTableHeader(l10n: l10n),
              const SizedBox(height: 8),
              linesList,
            ],
          ],
        );
        if (constraints.maxWidth >= minTableWidth) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: tableWidth, child: table),
        );
      },
    );

    return WebBentoTile(
      minHeight: 0,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                lines.isEmpty
                    ? l10n.billLines
                    : '${l10n.billLines} (${lines.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                key: IntegrationKeys.billFormAddProduct,
                onPressed: onFocusProductSearch,
                icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                label: Text(l10n.addProduct),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pack search under the last line when the list is short (minHeight
          // fills leftover space below the field). Long lists scroll normally;
          // the dropdown flips upward if space below is tight.
          if (scrollableLines)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          linesContent,
                          const SizedBox(height: 16),
                          productSearch,
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else ...[
            linesContent,
            const SizedBox(height: 16),
            productSearch,
          ],
        ],
      ),
    );
  }

  Widget _productTile(BuildContext context, Product product, bool highlighted) {
    final outOfStock = product.stockCached <= 0;
    return Container(
      height: kWebSearchDropdownTileHeight,
      decoration: BoxDecoration(
        color: highlighted ? WebPalette.navyWash : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: WebPalette.hairline, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: outOfStock ? WebPalette.inkSoft : WebPalette.ink,
                  ),
                ),
                Text(
                  '${formatNpr(Paisa(product.referencePrice), showPaisa: false)} / ${product.unit}',
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: WebPalette.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StockBadge(product: product, compact: true),
        ],
      ),
    );
  }
}

class _EmptyLinesHint extends StatelessWidget {
  const _EmptyLinesHint({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: WebPalette.paperDeep.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WebPalette.hairline),
      ),
      child: Column(
        children: [
          const Icon(
            PhosphorIconsRegular.shoppingCart,
            size: 28,
            color: WebPalette.inkFaint,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noBillLines,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: WebPalette.inkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Right rail: customer selector, bill metadata, and totals.
class _CheckoutRail extends StatelessWidget {
  const _CheckoutRail({
    required this.l10n,
    required this.today,
    required this.selectedCustomer,
    this.customerLocked = false,
    required this.customerController,
    required this.customerFocus,
    required this.guestNameController,
    required this.customers,
    required this.customersLoading,
    required this.customersFailed,
    required this.onCustomerQueryChanged,
    required this.onCustomerSelected,
    required this.onCustomerCleared,
    required this.onGuestNameChanged,
    required this.itemsTotal,
    required this.billDiscountController,
    required this.grandTotal,
    required this.onDiscountChanged,
    this.showCustomerBalance = true,
  });

  final AppLocalizations l10n;
  final String today;
  final Customer? selectedCustomer;
  final bool customerLocked;
  final TextEditingController customerController;
  final FocusNode customerFocus;
  final TextEditingController guestNameController;
  final List<Customer> customers;
  final bool customersLoading;
  final bool customersFailed;
  final ValueChanged<String> onCustomerQueryChanged;
  final ValueChanged<Customer> onCustomerSelected;
  final VoidCallback onCustomerCleared;
  final VoidCallback onGuestNameChanged;
  final int itemsTotal;
  final TextEditingController billDiscountController;
  final int grandTotal;
  final VoidCallback onDiscountChanged;
  final bool showCustomerBalance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WebBentoTile(
          minHeight: 0,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.customerName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              if (selectedCustomer == null) ...[
                WebSearchDropdown<Customer>(
                  controller: customerController,
                  focusNode: customerFocus,
                  hint: l10n.walkInCustomer,
                  hintIcon: PhosphorIconsRegular.userPlus,
                  items: customers,
                  loading: customersLoading,
                  emptyLabel: customersFailed
                      ? l10n.loadingFailed
                      : l10n.noSearchResults,
                  onQueryChanged: onCustomerQueryChanged,
                  onSelected: onCustomerSelected,
                  itemBuilder: _customerTile,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: guestNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.walkInNameHint),
                  onChanged: (_) => onGuestNameChanged(),
                ),
              ] else
                _SelectedCustomerChip(
                  customer: selectedCustomer!,
                  onCleared: customerLocked ? null : onCustomerCleared,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetaItem(label: l10n.billDate, value: today),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetaItem(
                      label: l10n.billNumber,
                      value: 'AUTO',
                      mutedValue: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BillSummary(
          style: BillSummaryStyle.card,
          accentColor: WebPalette.navy,
          cardBackground: WebPalette.navy.withValues(alpha: 0.04),
          cardBorderColor: WebPalette.navy.withValues(alpha: 0.12),
          itemsTotal: itemsTotal,
          billDiscountController: billDiscountController,
          grandTotal: grandTotal,
          onDiscountChanged: onDiscountChanged,
        ),
      ],
    );
  }

  Widget _customerTile(
    BuildContext context,
    Customer customer,
    bool highlighted,
  ) {
    final subtitle = customer.contactName ?? customer.phone ?? '';
    return Container(
      height: kWebSearchDropdownTileHeight,
      decoration: BoxDecoration(
        color: highlighted ? WebPalette.navyWash : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: WebPalette.hairline, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.storefront,
            size: 18,
            color: WebPalette.inkSoft,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: WebPalette.inkSoft),
                  ),
              ],
            ),
          ),
          if (showCustomerBalance && customer.balanceDue > 0) ...[
            const SizedBox(width: 8),
            Text(
              formatNpr(Paisa(customer.balanceDue), showPaisa: false),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WebPalette.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedCustomerChip extends StatelessWidget {
  const _SelectedCustomerChip({required this.customer, this.onCleared});

  final Customer customer;
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitle = customer.contactName ?? customer.phone ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WebPalette.navyWash,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WebPalette.navy.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.storefront,
            size: 18,
            color: WebPalette.navy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: WebPalette.inkSoft),
                  ),
              ],
            ),
          ),
          if (onCleared != null)
            IconButton(
              tooltip: l10n.remove,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                PhosphorIconsRegular.x,
                size: 16,
                color: WebPalette.inkSoft,
              ),
              onPressed: onCleared,
            ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.label,
    required this.value,
    this.mutedValue = false,
  });

  final String label;
  final String value;
  final bool mutedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: WebPalette.inkSoft),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: mutedValue ? WebPalette.inkSoft : WebPalette.ink,
          ),
        ),
      ],
    );
  }
}
