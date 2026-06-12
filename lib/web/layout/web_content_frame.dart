import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';

/// Centers page content with max-width and generous gutters.
class WebContentFrame extends StatelessWidget {
  const WebContentFrame({
    super.key,
    required this.child,
    this.padding,
    this.fillHeight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = context.webTokens;
    final horizontal = context.isWebCompact ? 16.0 : tokens.pagePadding;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: tokens.contentMaxWidth,
          minHeight: fillHeight ? MediaQuery.sizeOf(context).height : 0,
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
          child: child,
        ),
      ),
    );
  }
}
