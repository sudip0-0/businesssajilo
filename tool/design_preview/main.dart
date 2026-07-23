// Design preview harness — renders the "Digital Ledger" web design system
// with realistic mock data, no backend required.
//
// Run:
//   flutter run -t tool/design_preview/main.dart -d web-server --web-port 52201
//
// Dev-only tool; nothing here ships in the app bundle.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/core/ui/bill_status_chip.dart';
import 'package:businesssajilo/core/ui/bs_sales_line_chart.dart';
import 'package:businesssajilo/core/utils/money.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/sales_period_point.dart';
import 'package:businesssajilo/web/layout/web_bento_grid.dart';
import 'package:businesssajilo/web/layout/web_page_header.dart';
import 'package:businesssajilo/web/layout/web_sidebar.dart';
import 'package:businesssajilo/web/theme/web_palette.dart';
import 'package:businesssajilo/web/theme/web_theme.dart';
import 'package:businesssajilo/web/theme/web_typography.dart';
import 'package:businesssajilo/web/ui/web_data_table.dart';
import 'package:businesssajilo/web/ui/web_empty_state.dart';
import 'package:businesssajilo/web/ui/web_form_card.dart';
import 'package:businesssajilo/web/ui/web_paper.dart';
import 'package:businesssajilo/web/ui/web_search_field.dart';
import 'package:businesssajilo/web/ui/web_skeleton.dart';
import 'package:businesssajilo/web/ui/web_stat_tile.dart';

void main() {
  runApp(const DesignPreviewApp());
}

class DesignPreviewApp extends StatelessWidget {
  const DesignPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => _PreviewShell(child: child),
          routes: [
            GoRoute(path: '/', redirect: (_, _) => '/dashboard'),
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const _DashboardPage(),
            ),
            GoRoute(path: '/billing', builder: (_, _) => const _BillingPage()),
            GoRoute(path: '/forms', builder: (_, _) => const _FormsPage()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Design Preview',
      debugShowCheckedModeBanner: false,
      theme: WebTheme.light(),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

const _navItems = [
  WebNavItem(
    label: 'Dashboard',
    path: '/dashboard',
    icon: PhosphorIconsRegular.squaresFour,
  ),
  WebNavItem(
    label: 'Inventory',
    path: '/inventory',
    icon: PhosphorIconsRegular.package,
  ),
  WebNavItem(
    label: 'Billing',
    path: '/billing',
    icon: PhosphorIconsRegular.receipt,
  ),
  WebNavItem(
    label: 'Customers',
    path: '/customers',
    icon: PhosphorIconsRegular.storefront,
  ),
  WebNavItem(
    label: 'Orders',
    path: '/orders',
    icon: PhosphorIconsRegular.shoppingCart,
    badge: '5',
  ),
  WebNavItem(
    label: 'Reports',
    path: '/reports',
    icon: PhosphorIconsRegular.chartBar,
  ),
  WebNavItem(
    label: 'Staff',
    path: '/staff',
    icon: PhosphorIconsRegular.users,
  ),
  WebNavItem(
    label: 'Settings',
    path: '/settings',
    icon: PhosphorIconsRegular.gear,
  ),
];

class _PreviewShell extends StatefulWidget {
  const _PreviewShell({required this.child});

  final Widget child;

  @override
  State<_PreviewShell> createState() => _PreviewShellState();
}

class _PreviewShellState extends State<_PreviewShell> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          WebSidebar(
            items: _navItems,
            collapsed: _collapsed,
            onToggleCollapse: () =>
                setState(() => _collapsed = !_collapsed),
            footer: SizedBox(
              width: double.infinity,
              child: _collapsed
                  ? Center(
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(PhosphorIconsRegular.plus, size: 18),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                      label: const Text('Create New Bill'),
                    ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const _MockTopBar(),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: widget.child),
                      const Positioned.fill(child: WebPaperGrain()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Static replica of the real WebTopBar (which binds to backend providers).
class _MockTopBar extends StatelessWidget {
  const _MockTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: WebPalette.card,
        border: Border(bottom: BorderSide(color: WebPalette.hairline)),
      ),
      child: Row(
        children: [
          const Spacer(),
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(48, 32),
            ),
            segments: const [
              ButtonSegment(value: 'en', label: Text('EN')),
              ButtonSegment(value: 'ne', label: Text('NE')),
            ],
            selected: const {'en'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: const Badge(
              backgroundColor: WebPalette.brass,
              label: Text(
                '3',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Icon(
                PhosphorIconsRegular.bell,
                color: WebPalette.inkSoft,
                size: 21,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              PhosphorIconsRegular.gear,
              color: WebPalette.inkSoft,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WebPalette.navyWash,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: WebPalette.navy.withValues(alpha: 0.14)),
            ),
            child: const Text(
              'S',
              style: TextStyle(
                color: WebPalette.navy,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sita',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: WebPalette.ink),
              ),
              Text(
                'Owner',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: WebPalette.inkFaint,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              PhosphorIconsRegular.signOut,
              color: WebPalette.inkSoft,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard ──────────────────────────────────────────────────────────

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    final points = [
      for (var i = 0; i < 7; i++)
        SalesPeriodPoint(
          saleDate: DateTime.now().subtract(Duration(days: 6 - i)),
          billCount: 3 + (i % 3),
          totalSales: const [38000, 52000, 44500, 61000, 58700, 73400, 84250][i] * 100,
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WebPageHeader(
            title: 'Namaste, Sita',
            subtitle: 'Here is what is happening in your business today.',
            breadcrumbs: ['Home', 'Dashboard'],
            actions: [],
          ),
          Row(
            children: [
              const Spacer(),
              OutlinedButton(onPressed: () {}, child: const Text('Add Product')),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(PhosphorIconsRegular.receipt, size: 18),
                label: const Text('New Bill'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          WebBentoGrid(
            children: [
              WebStatTile(
                label: "Today's Sales",
                value: formatNpr(const Paisa(8425000), showPaisa: false),
                icon: PhosphorIconsRegular.currencyCircleDollar,
                trend: WebTrendDirection.up,
                trendLabel: '12%',
                onTap: () {},
              ),
              WebStatTile(
                label: 'Total Dues',
                value: formatNpr(const Paisa(23480000), showPaisa: false),
                icon: PhosphorIconsRegular.wallet,
                onTap: () {},
              ),
              WebStatTile(
                label: 'Low Stock',
                value: '7 products',
                icon: PhosphorIconsRegular.package,
                subtitle: 'Reorder soon',
                onTap: () {},
              ),
              WebStatTile(
                label: 'Pending Orders',
                value: '5 orders',
                icon: PhosphorIconsRegular.shoppingCart,
                trend: WebTrendDirection.neutral,
                trendLabel: '5 new',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: WebBentoTile(
                  minHeight: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sales Performance',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  'Daily sales for the last 7 days',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: WebPalette.inkSoft),
                                ),
                              ],
                            ),
                          ),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            segments: const [
                              ButtonSegment(value: true, label: Text('Weekly')),
                              ButtonSegment(
                                value: false,
                                label: Text('Monthly'),
                              ),
                            ],
                            selected: const {true},
                            onSelectionChanged: (_) {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      BsSalesLineChart(
                        points: points,
                        height: 220,
                        period: SalesChartPeriod.weekly,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    WebBentoTile(
                      minHeight: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Stock Check',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          WebSearchField(
                            hint: 'Filter products…',
                            onSubmitted: (_) {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    WebBentoTile(
                      minHeight: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 14),
                          const _ActivityRow(
                            icon: PhosphorIconsRegular.receipt,
                            color: WebPalette.navy,
                            text: 'New bill INV-0142 created',
                          ),
                          const SizedBox(height: 12),
                          const _ActivityRow(
                            icon: PhosphorIconsRegular.warning,
                            color: WebPalette.danger,
                            text: 'Low stock: Wai Wai Noodles (carton)',
                          ),
                          const SizedBox(height: 12),
                          const _ActivityRow(
                            icon: PhosphorIconsRegular.user,
                            color: WebPalette.success,
                            text: 'Sagarmatha Traders added as customer',
                          ),
                          const SizedBox(height: 12),
                          const _ActivityRow(
                            icon: PhosphorIconsRegular.receipt,
                            color: WebPalette.navy,
                            text: 'Payment received from Aarati Suppliers',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          WebBentoTile(
            minHeight: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      "Today's Transactions",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(PhosphorIconsRegular.export, size: 16),
                      label: const Text('Export'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _TransactionsPreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _TransactionsPreview extends StatelessWidget {
  const _TransactionsPreview();

  static const _rows = [
    ('#0142', 'Sagarmatha Traders', '10:24 AM', 'Cash', 1845000, BillStatus.paid),
    ('#0141', 'Aarati Suppliers', '09:58 AM', 'Partial', 5620000, BillStatus.partial),
    ('#0140', 'Walk-in customer', '09:31 AM', 'Cash', 1285000, BillStatus.paid),
    ('#0139', 'Himalayan General Store', '08:47 AM', 'Due', 3478000, BillStatus.due),
    ('#0138', 'New Road Kirana Pasal', '08:12 AM', 'Cash', 964000, BillStatus.paid),
  ];

  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 52,
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('S.N.')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Time')),
        DataColumn(label: Text('Payment')),
        DataColumn(label: Text('Amount (NPR)')),
        DataColumn(label: Text('Status')),
      ],
      rows: [
        for (final r in _rows)
          DataRow(
            onSelectChanged: (_) {},
            cells: [
              DataCell(
                Text(
                  r.$1,
                  style: WebTypography.mono(
                    fontSize: 12,
                    color: WebPalette.inkSoft,
                  ),
                ),
              ),
              DataCell(Text(r.$2)),
              DataCell(Text(r.$3)),
              DataCell(Text(r.$4)),
              DataCell(
                Text(
                  formatNpr(Paisa(r.$5), showPaisa: false),
                  style: WebTypography.mono(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: WebPalette.ink,
                  ),
                ),
              ),
              DataCell(BillStatusChip(r.$6)),
            ],
          ),
      ],
    );
  }
}

// ── Billing list ───────────────────────────────────────────────────────

class _BillingPage extends StatelessWidget {
  const _BillingPage();

  static const _bills = [
    ('INV-0142', 'Sagarmatha Traders', '18 Jul, 10:24 AM', 5, 1845000, BillStatus.paid),
    ('INV-0141', 'Aarati Suppliers', '18 Jul, 09:58 AM', 12, 5620000, BillStatus.partial),
    ('INV-0140', 'Walk-in customer', '18 Jul, 09:31 AM', 2, 1285000, BillStatus.paid),
    ('INV-0139', 'Himalayan General Store', '18 Jul, 08:47 AM', 8, 3478000, BillStatus.due),
    ('INV-0138', 'New Road Kirana Pasal', '17 Jul, 05:12 PM', 3, 964000, BillStatus.paid),
    ('INV-0137', 'Bishal Bazaar Store', '17 Jul, 03:40 PM', 17, 7214000, BillStatus.partial),
    ('INV-0136', 'Pokhara Wholesale Depot', '17 Jul, 01:05 PM', 9, 4190000, BillStatus.paid),
    ('INV-0135', 'Dharan Traders', '16 Jul, 04:52 PM', 6, 2875000, BillStatus.due),
    ('INV-0134', 'Butwal Kirana House', '16 Jul, 11:18 AM', 4, 1530000, BillStatus.paid),
    ('INV-0133', 'Chitwan Suppliers', '15 Jul, 02:36 PM', 11, 6048000, BillStatus.paid),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: WebPageHeader(
                  title: 'Billing',
                  subtitle: 'Create and manage customer bills.',
                  breadcrumbs: ['Home', 'Billing'],
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                label: const Text('New Bill'),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 320,
                child: WebSearchField(
                  hint: 'Search bills…',
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(PhosphorIconsRegular.funnel, size: 16),
                label: const Text('Filter'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: WebDataTable<
              (String, String, String, int, int, BillStatus)
            >(
              columns: const [
                DataColumn(label: Text('Bill No.')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Items'), numeric: true),
                DataColumn(label: Text('Total (NPR)'), numeric: true),
                DataColumn(label: Text('Status')),
              ],
              items: _bills,
              totalItems: 132,
              page: 0,
              onPageChanged: (_) {},
              onRowTap: (_) {},
              rowBuilder: (bill, index) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        bill.$1,
                        style: WebTypography.mono(
                          fontSize: 12,
                          color: WebPalette.inkSoft,
                        ),
                      ),
                    ),
                    DataCell(Text(bill.$2)),
                    DataCell(Text(bill.$3)),
                    DataCell(
                      Text(
                        '${bill.$4}',
                        style: WebTypography.mono(
                          fontSize: 12.5,
                          color: WebPalette.inkSoft,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        formatNpr(Paisa(bill.$5)),
                        style: WebTypography.mono(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: WebPalette.ink,
                        ),
                      ),
                    ),
                    DataCell(BillStatusChip(bill.$6)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Forms / states ─────────────────────────────────────────────────────

class _FormsPage extends StatelessWidget {
  const _FormsPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WebPageHeader(
            title: 'New Customer',
            subtitle: 'Add a shop or dealer to your network.',
            breadcrumbs: ['Customers', 'New customer'],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: WebFormCard(
                  title: 'Customer Details',
                  subtitle: 'Basic information about the shop.',
                  icon: PhosphorIconsRegular.storefront,
                  children: [
                    const WebFormSectionLabel('Identity'),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Shop name',
                        hintText: 'e.g. Sagarmatha Traders',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const WebFormRow(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Owner name',
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(labelText: 'Phone'),
                        ),
                      ],
                    ),
                    const WebFormSectionLabel('Location'),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Street, city',
                      ),
                    ),
                    const SizedBox(height: 18),
                    const WebInfoTipCard(
                      message:
                          'Customer dues are tracked automatically once the first bill is created.',
                      color: WebPalette.brassDeep,
                      icon: PhosphorIconsRegular.lightbulb,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(PhosphorIconsRegular.check, size: 18),
                          label: const Text('Save Customer'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                flex: 2,
                child: Column(
                  children: [
                    WebBentoTile(
                      minHeight: 220,
                      child: Column(
                        children: [
                          SizedBox(height: 8),
                          Expanded(
                            child: WebEmptyState(
                              message: 'No customers yet. Add your first shop to start billing.',
                              actionLabel: 'Add Customer',
                              icon: PhosphorIconsRegular.storefront,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    WebBentoTile(
                      minHeight: 220,
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        height: 220,
                        child: WebListSkeleton(itemCount: 4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
