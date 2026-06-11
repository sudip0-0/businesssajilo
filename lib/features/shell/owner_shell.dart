import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../staff/add_member_sheet.dart';
import '../staff/staff_list_screen.dart';
import 'logout_action.dart';
import 'role_dashboard.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      RoleDashboard(
        stats: [
          (icon: Icons.payments, label: l10n.todaysSales, value: 'रू 0'),
          (icon: Icons.account_balance_wallet, label: l10n.totalDues, value: 'रू 0'),
          (icon: Icons.inventory_2, label: l10n.lowStock, value: '0'),
          (icon: Icons.shopping_cart, label: l10n.pendingOrders, value: '0'),
        ],
      ),
      const StaffListScreen(),
      Center(child: Text(l10n.settings)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 1 ? l10n.staffManagement : l10n.dashboard),
        actions: const [LogoutAction()],
      ),
      body: pages[_index],
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddMemberSheet(),
                );
                if (created == true) ref.invalidate(staffListProvider);
              },
              icon: const Icon(Icons.person_add),
              label: Text(l10n.addMember),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.staff,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
