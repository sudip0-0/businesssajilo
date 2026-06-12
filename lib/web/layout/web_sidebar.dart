import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
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
  });

  final List<WebNavItem> items;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.webTokens;
    final location = GoRouterState.of(context).uri.path;
    final width =
        collapsed ? tokens.sidebarCollapsedWidth : tokens.sidebarWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(collapsed ? 12 : 20, 20, 12, 16),
            child: Row(
              children: [
                if (!collapsed) ...[
                  Icon(PhosphorIconsRegular.storefront,
                      color: BsColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BsColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
                IconButton(
                  tooltip: collapsed ? 'Expand' : 'Collapse',
                  onPressed: onToggleCollapse,
                  icon: Icon(
                    collapsed
                        ? PhosphorIconsRegular.caretRight
                        : PhosphorIconsRegular.caretLeft,
                    size: 18,
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
                  collapsed: collapsed,
                  onTap: () => context.go(item.path),
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
              ? scheme.primary.withValues(alpha: 0.1)
              : _hovered
                  ? scheme.surfaceContainerLow
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
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
                    color: widget.selected ? BsColors.primary : scheme.onSurface,
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
                                  ? BsColors.primary
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.item.badge!,
                          style: Theme.of(context).textTheme.labelSmall,
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
