import 'package:flutter/material.dart';

import '../layout/bs_breakpoints.dart';

bool isWideLayout(BuildContext context) =>
    BsBreakpoints.isTabletWideOrWider(context);

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.titles,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final List<String> titles;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final title = selectedIndex < titles.length ? titles[selectedIndex] : '';

    final appBar = AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      titleSpacing: 16,
      actionsPadding: const EdgeInsets.only(right: 4),
      actions: actions,
    );

    if (!wide) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon ?? d.icon,
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
