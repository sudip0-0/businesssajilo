import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centered dialog for web forms (replaces bottom sheets).
Future<T?> showWebDialog<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  List<Widget>? actions,
  double maxWidth = 520,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(ctx).pop(),
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 20),
                Flexible(child: SingleChildScrollView(child: child)),
                if (actions != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
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
