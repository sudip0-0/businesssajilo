import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../domain/enums.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/search/global_search_sheet.dart';
import '../router/web_role_routes.dart';
import '../theme/web_tokens.dart';
import '../ui/web_keyboard_scope.dart';
import '../ui/web_paper.dart';
import '../widgets/web_shortcuts_dialog.dart';
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
  bool _searchOpen = false;
  bool _shortcutsOpen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _isEditingTextField() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  int? _altDigitIndex(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      return 0;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      return 1;
    }
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      return 2;
    }
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      return 3;
    }
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      return 4;
    }
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      return 5;
    }
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      return 6;
    }
    return null;
  }

  Future<void> _openGlobalSearch() async {
    if (_searchOpen || !mounted) return;
    _searchOpen = true;
    try {
      await showGlobalSearch(context, ref);
    } finally {
      _searchOpen = false;
    }
  }

  Future<void> _openShortcutsDialog() async {
    if (_shortcutsOpen || !mounted) return;
    _shortcutsOpen = true;
    final role = ref.read(authProvider).value?.member?.role;
    final canCreateBill = role?.canBill ?? false;
    try {
      await showWebShortcutsDialog(
        context,
        navItems: widget.navItems,
        canCreateBill: canCreateBill,
      );
    } finally {
      _shortcutsOpen = false;
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    if (!TickerMode.valuesOf(context).enabled) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final kb = HardwareKeyboard.instance;
    final ctrlOrMeta = kb.isControlPressed || kb.isMetaPressed;
    final alt = kb.isAltPressed;
    final shift = kb.isShiftPressed;
    final key = event.logicalKey;

    if (ctrlOrMeta && !alt && key == LogicalKeyboardKey.keyK) {
      _openGlobalSearch();
      return true;
    }

    if (alt && !ctrlOrMeta) {
      if (key == LogicalKeyboardKey.keyN || key == LogicalKeyboardKey.keyB) {
        final role = ref.read(authProvider).value?.member?.role;
        if (role != null && role.canBill) {
          final target = '${webRoleBasePath(role)}/billing/new';
          final current = GoRouterState.of(context).uri.path;
          if (current != target) {
            context.go(target);
          }
          return true;
        }
        return false;
      }

      final navIndex = _altDigitIndex(key);
      if (navIndex != null && navIndex < widget.navItems.length) {
        context.go(widget.navItems[navIndex].path);
        return true;
      }
      return false;
    }

    if (!ctrlOrMeta && !alt && !_isEditingTextField()) {
      final isQuestion =
          event.character == '?' ||
          key == LogicalKeyboardKey.question ||
          (key == LogicalKeyboardKey.slash && shift);
      if (isQuestion) {
        _openShortcutsDialog();
        return true;
      }

      final isSlash =
          event.character == '/' || (key == LogicalKeyboardKey.slash && !shift);
      if (isSlash) {
        _openGlobalSearch();
        return true;
      }
    }

    return false;
  }

  void _openMobileDrawer() {
    final location = GoRouterState.of(context).uri.path;
    final router = GoRouter.of(context);
    var drawerOpen = true;
    BuildContext? sheetCtx;

    void onRouteChanged() {
      if (!drawerOpen || sheetCtx == null) return;
      final nextLocation = router.routeInformationProvider.value.uri.path;
      if (nextLocation != location && sheetCtx!.mounted) {
        drawerOpen = false;
        Navigator.of(sheetCtx!).pop();
      }
    }

    router.routerDelegate.addListener(onRouteChanged);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        sheetCtx = sheetContext;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.88,
          builder: (context, scrollController) => WebSidebar(
            items: widget.navItems,
            collapsed: false,
            onToggleCollapse: () {},
            footer: widget.sidebarFooter?.call(false),
            inDrawer: true,
            location: location,
            onNavigate: (path) {
              drawerOpen = false;
              Navigator.of(sheetContext).pop();
              router.go(path);
            },
          ),
        );
      },
    ).whenComplete(() {
      drawerOpen = false;
      router.routerDelegate.removeListener(onRouteChanged);
    });
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
                    onOpenShortcuts: _openShortcutsDialog,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          // Route BlockSemantics must stay inside the content
                          // boundary rather than hiding persistent shell controls.
                          child: Semantics(
                            container: true,
                            explicitChildNodes: true,
                            child: FocusTraversalGroup(
                              child: SelectionArea(child: widget.child),
                            ),
                          ),
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
      height: 68,
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
