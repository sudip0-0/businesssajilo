import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/web_palette.dart';
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
          final lastSpansRow =
              lastItemSpansFullWidth &&
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
                  .fadeIn(duration: 340.ms, delay: (index * 55).ms)
                  .slideY(
                    begin: 0.04,
                    end: 0,
                    duration: 340.ms,
                    curve: Curves.easeOutCubic,
                  );
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

/// Metric / content card — warm paper card with an ink-tinted hover lift.
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
    final interactive = widget.onTap != null;
    final lifted = _hovered && interactive;

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
        transformAlignment: Alignment.center,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        decoration: BoxDecoration(
          color: WebPalette.card,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(
            color: lifted ? WebPalette.hairlineStrong : WebPalette.hairline,
          ),
          boxShadow: lifted || widget.elevated
              ? tokens.metricShadow
              : WebPalette.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: !interactive
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
