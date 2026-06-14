import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../theme/web_tokens.dart';

/// Dashboard metric grid with 3-4 column layout per Design.md.
class WebBentoGrid extends StatelessWidget {
  const WebBentoGrid({
    super.key,
    required this.children,
    this.columns = 4,
  });

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final compact = context.isWebCompact;
    final tokens = context.webTokens;
    final cols = compact ? 1 : (columns > 2 ? columns : 3);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = tokens.gutter;
        final cellWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: compact
                    ? constraints.maxWidth
                    : _spanWidth(i, cellWidth, gap, cols, children.length),
                child: children[i]
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (i * 60).ms)
                    .slideY(begin: 0.03, end: 0, duration: 300.ms),
              ),
          ],
        );
      },
    );
  }

  double _spanWidth(int index, double cell, double gap, int cols, int count) {
    if (index == count - 1 && cols >= 2) {
      return cell * cols + gap * (cols - 1);
    }
    return cell;
  }
}

/// Metric / content card with Level 2 elevation on hover.
class WebBentoTile extends StatefulWidget {
  const WebBentoTile({
    super.key,
    required this.child,
    this.minHeight = 140,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.elevated = false,
  });

  final Widget child;
  final double minHeight;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool elevated;

  @override
  State<WebBentoTile> createState() => _WebBentoTileState();
}

class _WebBentoTileState extends State<WebBentoTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.webTokens;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(
            color: _hovered ? BsColors.outlineVariant : BsColors.border,
          ),
          boxShadow: widget.elevated || _hovered ? tokens.metricShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: widget.onTap == null
              ? Padding(padding: widget.padding, child: widget.child)
              : InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(tokens.cardRadius),
                  child: Padding(padding: widget.padding, child: widget.child),
                ),
        ),
      ),
    );
  }
}
