import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/testing/integration_keys.dart';
import '../theme/web_palette.dart';
import '../theme/web_tokens.dart';
import '../theme/web_typography.dart';

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

/// The ink-navy rail — the signature spine of the web experience.
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
    final isCollapsed = collapsed && !inDrawer;
    final width = isCollapsed
        ? tokens.sidebarCollapsedWidth
        : tokens.sidebarWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: inDrawer ? null : width,
      decoration: const BoxDecoration(gradient: WebPalette.railGradient),
      child: Column(
        children: [
          _BrandBlock(
            collapsed: isCollapsed,
            inDrawer: inDrawer,
            l10n: l10n,
            onToggleCollapse: onToggleCollapse,
          ),
          const Divider(height: 1, color: WebPalette.railLine),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                isCollapsed ? 10 : 12,
                14,
                isCollapsed ? 10 : 12,
                8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = location.startsWith(item.path);

                return _SidebarTile(
                      item: item,
                      selected: selected,
                      collapsed: isCollapsed,
                      onTap: () {
                        context.go(item.path);
                        if (inDrawer) Navigator.of(context).pop();
                      },
                    )
                    .animate()
                    .fadeIn(duration: 260.ms, delay: (40 + index * 30).ms)
                    .slideX(
                      begin: -0.04,
                      end: 0,
                      duration: 260.ms,
                      delay: (40 + index * 30).ms,
                      curve: Curves.easeOutCubic,
                    );
              },
            ),
          ),
          if (footer != null) ...[
            const Divider(height: 1, color: WebPalette.railLine),
            // Footer CTAs (e.g. "Create bill") take the brass treatment so
            // they stay legible on the dark rail.
            Theme(
              data: Theme.of(context).copyWith(
                filledButtonTheme: FilledButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return WebPalette.brass;
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return WebPalette.brassBright;
                      }
                      return WebPalette.brass;
                    }),
                    foregroundColor: WidgetStateProperty.all(
                      const Color(0xFF241A05),
                    ),
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.14),
                    ),
                    minimumSize: WidgetStateProperty.all(const Size(64, 40)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isCollapsed ? 12 : 14),
                child: footer!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({
    required this.collapsed,
    required this.inDrawer,
    required this.l10n,
    required this.onToggleCollapse,
  });

  final bool collapsed;
  final bool inDrawer;
  final AppLocalizations l10n;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final mark = Tooltip(
      message: collapsed ? l10n.sidebarExpand : l10n.appTitle,
      child: InkWell(
        onTap: collapsed && !inDrawer ? onToggleCollapse : null,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: WebPalette.brass.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: WebPalette.brassBright.withValues(alpha: 0.4),
            ),
          ),
          child: const Icon(
            PhosphorIconsRegular.storefront,
            color: WebPalette.brassBright,
            size: 20,
          ),
        ),
      ),
    );

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 14),
        child: Center(child: mark),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 14),
      child: Row(
        children: [
          mark,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WebTypography.serif(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: WebPalette.railTextBright,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  l10n.smeManagement.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WebTypography.eyebrow(
                    color: WebPalette.railText.withValues(alpha: 0.75),
                  ).copyWith(fontSize: 9, letterSpacing: 1.6),
                ),
              ],
            ),
          ),
          if (!inDrawer)
            IconButton(
              tooltip: l10n.sidebarCollapse,
              onPressed: onToggleCollapse,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                PhosphorIconsRegular.caretLeft,
                size: 17,
                color: WebPalette.railText,
              ),
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
    final selected = widget.selected;
    final background = selected
        ? WebPalette.railRaised
        : _hovered
        ? WebPalette.railRaised.withValues(alpha: 0.55)
        : Colors.transparent;
    final iconColor = selected
        ? WebPalette.brassBright
        : _hovered
        ? WebPalette.railTextBright
        : WebPalette.railText;
    final textColor = selected
        ? WebPalette.railTextBright
        : _hovered
        ? WebPalette.railTextBright
        : WebPalette.railText;

    final tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(7),
        ),
        child: InkWell(
          key: IntegrationKeys.sidebarNav(widget.item.path),
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(7),
          splashColor: WebPalette.brass.withValues(alpha: 0.12),
          highlightColor: WebPalette.brass.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 12,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // Brass selection tick — the ledger bookmark.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 3,
                  height: selected ? 18 : 0,
                  margin: EdgeInsets.only(right: widget.collapsed ? 0 : 9),
                  decoration: BoxDecoration(
                    color: WebPalette.brassBright,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(widget.item.icon, size: 20, color: iconColor),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (widget.item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: WebPalette.brassBright,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.item.badge!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF241A05),
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: widget.collapsed
          ? Tooltip(message: widget.item.label, child: tile)
          : tile,
    );
  }
}
