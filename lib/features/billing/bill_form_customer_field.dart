import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/customer.dart';
import '../customers/providers.dart';

/// Searchable customer picker that never unmounts the text field while
/// results load, so the keyboard stays up while typing.
class BillCustomerSearchField extends ConsumerStatefulWidget {
  const BillCustomerSearchField({
    super.key,
    this.selectedCustomer,
    this.selectedName,
    required this.onCustomerSelected,
    this.onTextChanged,
    this.enabled = true,
  });

  final Customer? selectedCustomer;

  /// Shop name when [selectedCustomer] is not loaded yet (e.g. id prefill).
  final String? selectedName;
  final ValueChanged<Customer?> onCustomerSelected;
  final ValueChanged<String>? onTextChanged;
  final bool enabled;

  @override
  ConsumerState<BillCustomerSearchField> createState() =>
      _BillCustomerSearchFieldState();
}

class _BillCustomerSearchFieldState
    extends ConsumerState<BillCustomerSearchField> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  List<Customer> _lastCustomers = const [];
  String _lastQuery = '';
  bool _loadedOnce = false;
  bool _showSuggestions = false;

  String get _displayName =>
      widget.selectedCustomer?.shopName ?? widget.selectedName ?? '';

  @override
  void initState() {
    super.initState();
    _controller.text = _displayName;
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant BillCustomerSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.selectedCustomer?.id;
    final newId = widget.selectedCustomer?.id;
    final oldName = oldWidget.selectedName;
    final newName = widget.selectedName;
    if (_focus.hasFocus) return;
    if (oldId == newId && oldName == newName) return;
    final next = _displayName;
    if (_controller.text != next) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _showSuggestions = _focus.hasFocus);
  }

  void _onQueryChanged(String raw) {
    widget.onTextChanged?.call(raw);
    final selectedName = _displayName;
    final hadSelection =
        widget.selectedCustomer != null || selectedName.trim().isNotEmpty;
    if (hadSelection &&
        raw.trim().toLowerCase() != selectedName.trim().toLowerCase()) {
      widget.onCustomerSelected(null);
    }

    _debounce?.cancel();
    final query = raw.trim();
    setState(() {});
    if (query == _query) return;
    _debounce = Timer(_searchDebounce, () {
      if (mounted) setState(() => _query = query);
    });
  }

  void _selectWalkIn() {
    _controller.clear();
    widget.onTextChanged?.call('');
    widget.onCustomerSelected(null);
    _focus.unfocus();
  }

  void _selectCustomer(Customer customer) {
    _controller.text = customer.shopName;
    widget.onTextChanged?.call(customer.shopName);
    widget.onCustomerSelected(customer);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen(customerListProvider(_query), (_, next) {
      final value = next.value;
      if (value != null) {
        setState(() {
          _lastCustomers = value;
          _lastQuery = _query;
          _loadedOnce = true;
        });
      }
    });

    final customersAsync = ref.watch(customerListProvider(_query));
    final liveQuery = _controller.text.trim();
    final customers = liveQuery == _lastQuery
        ? (customersAsync.value ?? _lastCustomers)
        : const <Customer>[];
    final refreshing =
        (liveQuery.isNotEmpty && liveQuery != _lastQuery) ||
        (liveQuery == _query && customersAsync.isLoading && _loadedOnce);
    final loadFailed = customersAsync.hasError && !_loadedOnce;

    final subtitle = widget.selectedCustomer != null
        ? (widget.selectedCustomer!.contactName ??
              widget.selectedCustomer!.phone ??
              l10n.customerName)
        : l10n.walkIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.customerName,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: BsColors.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: BsColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(BsRadii.xl),
            border: Border.all(
              color: _focus.hasFocus
                  ? BsColors.primary.withValues(alpha: 0.35)
                  : BsColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: BsColors.primary.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: BsColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: l10n.walkInCustomer,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.fromLTRB(0, 10, 8, 0),
                      ),
                      style: Theme.of(context).textTheme.titleSmall,
                      onChanged: _onQueryChanged,
                    ),
                    if (!_focus.hasFocus)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _controller.text.trim().isEmpty
                              ? l10n.walkIn
                              : subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: BsColors.outline),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  _showSuggestions
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: BsColors.outline,
                ),
              ),
            ],
          ),
        ),
        if (_showSuggestions && refreshing)
          const LinearProgressIndicator(minHeight: 2),
        if (_showSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              elevation: 2,
              color: Colors.white,
              borderRadius: BorderRadius.circular(BsRadii.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: loadFailed
                    ? Padding(
                        padding: const EdgeInsets.all(BsSpacing.lg),
                        child: Text(l10n.loadingFailed),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline),
                            title: Text(l10n.walkInCustomer),
                            subtitle: Text(l10n.walkIn),
                            onTap: _selectWalkIn,
                          ),
                          if (customers.isEmpty && !refreshing && _loadedOnce)
                            ListTile(
                              dense: true,
                              enabled: false,
                              title: Text(l10n.noSearchResults),
                            )
                          else
                            for (final customer in customers)
                              ListTile(
                                dense: true,
                                title: Text(customer.shopName),
                                subtitle: Text(
                                  customer.phone ?? customer.contactName ?? '',
                                ),
                                onTap: () => _selectCustomer(customer),
                              ),
                        ],
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
