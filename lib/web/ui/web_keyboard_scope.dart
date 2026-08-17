import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps web pages with keyboard shortcuts and focus traversal defaults.
class WebKeyboardScope extends StatelessWidget {
  const WebKeyboardScope({
    super.key,
    required this.child,
    this.onEscape,
    this.bindings = const {},
  });

  final Widget child;
  final VoidCallback? onEscape;
  final Map<ShortcutActivator, VoidCallback> bindings;

  @override
  Widget build(BuildContext context) {
    final merged = <ShortcutActivator, VoidCallback>{...bindings};
    if (onEscape != null) {
      merged[const SingleActivator(LogicalKeyboardKey.escape)] = onEscape!;
    }

    return CallbackShortcuts(
      bindings: merged,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: child,
      ),
    );
  }
}
