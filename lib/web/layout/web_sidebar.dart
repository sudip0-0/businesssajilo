import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/testing/integration_keys.dart';
import '../../core/theme/app_theme.dart';
import '../theme/web_tokens.dart';

class WebNavItem {
  const WebNavItem({
    required this.label,
    required this.path,
    required this.icon,
    this.badge,
  });

  final String label;
  final String path;
  final IconData icon;
  final String? badge;
}

class WebSidebar extends StatelessWidget {
  const WebSidebar({
    super.key,
    required this.items,
    required this.collapsed,
    required this.onToggleCollapse,
    this.footer,
    this.inDrawer = false,
  });

  final List<WebNavItem> items;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final Widget? footer;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.webTokens;
    final location = GoRouterState.of(context).uri.path;
    final width =
        collapsed ? tokens.sidebarCollapsedWidth : tokens.sidebarWidth;

    return Container(
      width: inDrawer ? null : width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: inDrawer
            ? null
            : Border(
                right: const BorderSide(color: BsColors.border),
              ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(collapsed ? 12 : 20, 20, 12, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: BsColors.primary,
                    borderRadius: BorderRadius.circular(BsRadii.md),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.storefront,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: BsColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          l10n.smeManagement,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: BsColors.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!inDrawer)
                  IconButton(
                    tooltip: collapsed ? 'Expand' : 'Collapse',
                    onPressed: onToggleCollapse,
                    icon: Icon(
                      collapsed
                          ? PhosphorIconsRegular.caretRight
                          : PhosphorIconsRegular.caretLeft,
                      size: 18,
                      color: BsColors.outline,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = location.startsWith(item.path);

                return _SidebarTile(
                  item: item,
                  selected: selected,
                  collapsed: collapsed && !inDrawer,
                  onTap: () {
                    context.go(item.path);
                    if (inDrawer) Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: footer!,
            ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final WebNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: widget.selected
              ? BsColors.secondary.withValues(alpha: 0.12)
              : _hovered
                  ? BsColors.rowHover
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(BsRadii.lg),
          child: InkWell(
            key: IntegrationKeys.sidebarNav(widget.item.path),
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(BsRadii.lg),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.collapsed ? 12 : 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.item.icon,
                    size: 20,
                    color: widget.selected ? BsColors.secondary : scheme.onSurface,
                  ),
                  if (!widget.collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: widget.selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: widget.selected
                                  ? BsColors.secondary
                                  : scheme.onSurface,
                            ),
                      ),
                    ),
                    if (widget.item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: BsColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(BsRadii.full),
                        ),
                        child: Text(
                          widget.item.badge!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: BsColors.amberTextOnTint,
                              ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
