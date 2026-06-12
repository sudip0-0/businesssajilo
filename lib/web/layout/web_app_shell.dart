import 'package:flutter/material.dart';

import '../ui/web_keyboard_scope.dart';
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
  final Widget? sidebarFooter;

  @override
  State<WebAppShell> createState() => _WebAppShellState();
}

class _WebAppShellState extends State<WebAppShell> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return WebKeyboardScope(
      child: Scaffold(
      body: Row(
        children: [
          WebSidebar(
            items: widget.navItems,
            collapsed: _collapsed,
            onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
            footer: widget.sidebarFooter,
          ),
          Expanded(
            child: Column(
              children: [
                const WebTopBar(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
