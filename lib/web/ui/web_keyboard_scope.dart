import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps web pages with Escape-to-close and focus traversal defaults.
class WebKeyboardScope extends StatelessWidget {
  const WebKeyboardScope({super.key, required this.child, this.onEscape});

  final Widget child;
  final VoidCallback? onEscape;

  @override
  Widget build(BuildContext context) {
    final bindings = <ShortcutActivator, VoidCallback>{};
    if (onEscape != null) {
      bindings[const SingleActivator(LogicalKeyboardKey.escape)] = onEscape!;
    }

    return CallbackShortcuts(
      bindings: bindings,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: child,
      ),
    );
  }
}
