import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/web_tokens.dart';
import '../ui/web_keyboard_scope.dart';
import '../ui/web_paper.dart';
import 'web_sidebar.dart';
import 'web_top_bar.dart';

/// Persistent web shell: sidebar + top bar + routed content.
class WebAppShell extends StatefulWidget {
  const WebAppShell({
    super.key,
    required this.navItems,
    required this.child,
    this.sidebarFooter,
  });

  final List<WebNavItem> navItems;
  final Widget child;
  final Widget Function(bool collapsed)? sidebarFooter;

  @override
  State<WebAppShell> createState() => _WebAppShellState();
}

class _WebAppShellState extends State<WebAppShell> {
  bool _collapsed = false;

  void _openMobileDrawer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (context, scrollController) => WebSidebar(
          items: widget.navItems,
          collapsed: false,
          onToggleCollapse: () {},
          footer: widget.sidebarFooter?.call(false),
          inDrawer: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isWebCompact;
    final location = GoRouterState.of(context).uri.path;

    return WebKeyboardScope(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Row(
          children: [
            if (!compact)
              WebSidebar(
                items: widget.navItems,
                collapsed: _collapsed,
                onToggleCollapse: () =>
                    setState(() => _collapsed = !_collapsed),
                footer: widget.sidebarFooter?.call(_collapsed),
              ),
            Expanded(
              child: Column(
                children: [
                  WebTopBar(
                    showMenuButton: compact,
                    onMenuPressed: _openMobileDrawer,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: widget.child),
                        // Paper grain breaks the flatness of the canvas
                        // without ever intercepting input.
                        const Positioned.fill(child: WebPaperGrain()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: compact
            ? _MobileBottomNav(
                items: widget.navItems.take(5).toList(),
                location: location,
              )
            : null,
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({required this.items, required this.location});

  final List<WebNavItem> items;
  final String location;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 64,
      selectedIndex: items
          .indexWhere((i) => location.startsWith(i.path))
          .clamp(0, items.length - 1),
      onDestinationSelected: (index) => context.go(items[index].path),
      destinations: [
        for (final item in items)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}
