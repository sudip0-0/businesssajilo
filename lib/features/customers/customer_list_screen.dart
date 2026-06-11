import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/layout/adaptive_scaffold.dart';
import '../../core/layout/two_pane_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/utils/money.dart';
import '../../domain/models/customer.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import 'providers.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({
    super.key,
    this.canEdit = false,
    this.canRecordPayments = false,
  });

  final bool canEdit;
  final bool canRecordPayments;

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _query = '';
  String? _selectedCustomerId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(customerListProvider);

    final listPane = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.filterCustomers,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: customersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (customers) {
              final filtered = customers.where((c) {
                if (_query.isEmpty) return true;
                return c.shopName.toLowerCase().contains(_query) ||
                    (c.contactName?.toLowerCase().contains(_query) ?? false) ||
                    (c.phone?.contains(_query) ?? false);
              }).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.storefront_outlined,
                  message: l10n.noCustomers,
                  actionLabel: widget.canEdit ? l10n.addCustomer : null,
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final customer = filtered[index];
                  return _CustomerTile(
                    customer: customer,
                    selected: _selectedCustomerId == customer.id,
                    onTap: () => _selectCustomer(context, customer),
                    onEdit: widget.canEdit
                        ? () => _openEdit(context, customer)
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    return TwoPaneLayout(
      listPane: listPane,
      detailPane: _selectedCustomerId == null
          ? null
          : CustomerDetailScreen(
              customerId: _selectedCustomerId!,
              canEdit: widget.canEdit,
              canRecordPayments: widget.canRecordPayments,
              embedded: true,
            ),
    );
  }

  void _selectCustomer(BuildContext context, Customer customer) {
    if (isWideLayout(context)) {
      setState(() => _selectedCustomerId = customer.id);
      return;
    }
    _openDetail(context, customer);
  }

  Future<void> _openDetail(BuildContext context, Customer customer) async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(
          customerId: customer.id,
          canEdit: widget.canEdit,
          canRecordPayments: widget.canRecordPayments,
        ),
      ),
    );
    if (refreshed == true) {
      ref.invalidate(customerListProvider);
      ref.invalidate(totalDuesProvider);
    }
  }

  Future<void> _openEdit(BuildContext context, Customer customer) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(customerId: customer.id),
      ),
    );
    if (saved == true) {
      ref.invalidate(customerListProvider);
      ref.invalidate(totalDuesProvider);
    }
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.onTap,
    this.onEdit,
    this.selected = false,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final due = customer.balanceDue;

    return ListTile(
      onTap: onTap,
      selected: selected,
      leading: CircleAvatar(
        backgroundColor: BsColors.primary.withValues(alpha: 0.12),
        child: Text(
          customer.shopName.isNotEmpty ? customer.shopName[0].toUpperCase() : '?',
          style: const TextStyle(color: BsColors.primary),
        ),
      ),
      title: Text(customer.shopName),
      subtitle: Text(
        [
          if (customer.contactName != null) customer.contactName!,
          if (customer.phone != null) customer.phone!,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatNpr(Paisa(due), showPaisa: false),
            style: theme.titleSmall?.copyWith(
              color: due > 0 ? BsColors.danger : BsColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
