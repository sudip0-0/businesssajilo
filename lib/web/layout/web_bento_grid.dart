import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../theme/web_tokens.dart';

/// Dashboard metric grid with responsive 1/2/4 column layout per Design.md.
class WebBentoGrid extends StatelessWidget {
  const WebBentoGrid({
    super.key,
    required this.children,
    this.columns = 4,
    this.lastItemSpansFullWidth = false,
  });

  final List<Widget> children;
  final int columns;
  final bool lastItemSpansFullWidth;

  int _resolveColumns(double width, WebTokens tokens) {
    if (width < tokens.compactBreakpoint) {
      return children.length <= 2 ? children.length : 2;
    }
    if (width < tokens.desktopBreakpoint) {
      return columns >= 4 ? 2 : columns.clamp(1, 3);
    }
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.webTokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _resolveColumns(constraints.maxWidth, tokens);
        final gap = tokens.gutter;
        final rows = <Widget>[];

        for (var i = 0; i < children.length; i += cols) {
          final rowItems = <Widget>[];
          final end = (i + cols).clamp(0, children.length);
          final countInRow = end - i;
          final isLastRow = end == children.length;
          final lastSpansRow = lastItemSpansFullWidth &&
              isLastRow &&
              countInRow == 1 &&
              children.length > 1;

          for (var j = 0; j < cols; j++) {
            final index = i + j;
            Widget cell;
            if (index >= children.length) {
              cell = const SizedBox.shrink();
            } else {
              cell = children[index]
                  .animate()
                  .fadeIn(duration: 300.ms, delay: (index * 60).ms)
                  .slideY(begin: 0.03, end: 0, duration: 300.ms);
            }

            if (lastSpansRow && index == children.length - 1) {
              rowItems.add(Expanded(child: cell));
              break;
            }

            rowItems.add(
              Expanded(
                child: index < children.length ? cell : const SizedBox.shrink(),
              ),
            );
            if (j < cols - 1 && index + 1 < end) {
              rowItems.add(SizedBox(width: gap));
            }
          }

          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowItems,
            ),
          );

          if (end < children.length) {
            rows.add(SizedBox(height: gap));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
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
