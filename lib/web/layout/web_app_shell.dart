import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../features/search/global_search_sheet.dart';
import '../theme/web_tokens.dart';
import '../ui/web_keyboard_scope.dart';
import '../ui/web_paper.dart';
import 'web_sidebar.dart';
import 'web_top_bar.dart';

/// Compact bottom-nav keeps at most 5 slots. With more destinations, the
/// first four stay on the bar and the rest are reached via a More sheet.
const _compactPrimaryCount = 4;
const _compactMaxWithoutMore = 5;

/// Persistent web shell: sidebar + top bar + routed content.
class WebAppShell extends ConsumerStatefulWidget {
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
  ConsumerState<WebAppShell> createState() => _WebAppShellState();
}

class _WebAppShellState extends ConsumerState<WebAppShell> {
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
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            showGlobalSearch(context, ref),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            showGlobalSearch(context, ref),
      },
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
                        Positioned.fill(
                          child: SelectionArea(child: widget.child),
                        ),
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
            ? _MobileBottomNav(items: widget.navItems, location: location)
            : null,
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({required this.items, required this.location});

  final List<WebNavItem> items;
  final String location;

  bool get _useMore => items.length > _compactMaxWithoutMore;

  List<WebNavItem> get _primary =>
      _useMore ? items.take(_compactPrimaryCount).toList() : items;

  List<WebNavItem> get _overflow =>
      _useMore ? items.skip(_compactPrimaryCount).toList() : const [];

  int _selectedIndex() {
    final primaryIndex = _primary.indexWhere(
      (i) => location.startsWith(i.path),
    );
    if (primaryIndex >= 0) return primaryIndex;
    if (_overflow.any((i) => location.startsWith(i.path))) {
      return _primary.length;
    }
    return 0;
  }

  Future<void> _openMore(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(l10n.more)),
              for (final item in _overflow)
                ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  selected: location.startsWith(item.path),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go(item.path);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = <NavigationDestination>[
      for (final item in _primary)
        NavigationDestination(icon: Icon(item.icon), label: item.label),
      if (_useMore)
        NavigationDestination(
          icon: const Icon(PhosphorIconsRegular.dotsThreeOutline),
          selectedIcon: const Icon(PhosphorIconsRegular.dotsThree),
          label: l10n.more,
        ),
    ];

    return NavigationBar(
      height: 64,
      selectedIndex: _selectedIndex().clamp(0, destinations.length - 1),
      onDestinationSelected: (index) {
        if (_useMore && index == _primary.length) {
          _openMore(context);
          return;
        }
        context.go(_primary[index].path);
      },
      destinations: destinations,
    );
  }
}
