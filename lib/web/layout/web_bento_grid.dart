import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../theme/web_tokens.dart';

/// Asymmetric bento grid for dashboards (design variance 8).
class WebBentoGrid extends StatelessWidget {
  const WebBentoGrid({
    super.key,
    required this.children,
    this.columns = 3,
  });

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final compact = context.isWebCompact;
    final cols = compact ? 1 : columns;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 16.0;
        final cellWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: compact
                    ? constraints.maxWidth
                    : _spanWidth(i, cellWidth, gap, cols),
                child: children[i]
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (i * 80).ms)
                    .slideY(begin: 0.05, end: 0, duration: 400.ms),
              ),
          ],
        );
      },
    );
  }

  double _spanWidth(int index, double cell, double gap, int cols) {
    // First tile spans 2 columns on wide layouts for asymmetry.
    if (index == 0 && cols >= 3) return cell * 2 + gap;
    return cell;
  }
}

/// Bento tile with diffusion shadow and hover elevation.
class WebBentoTile extends StatefulWidget {
  const WebBentoTile({
    super.key,
    required this.child,
    this.minHeight = 160,
    this.onTap,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final double minHeight;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<WebBentoTile> createState() => _WebBentoTileState();
}

class _WebBentoTileState extends State<WebBentoTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.webTokens;
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(tokens.bentoRadius),
          border: Border.all(
            color: scheme.outline.withValues(alpha: _hovered ? 0.25 : 0.12),
          ),
          boxShadow: _hovered
              ? [
                  ...tokens.diffusionShadow,
                  BoxShadow(
                    color: BsColors.primary.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : tokens.diffusionShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(tokens.bentoRadius),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
