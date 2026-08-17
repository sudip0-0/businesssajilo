import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Right-side panel for web workflows (payment, stock-in, add-member).
/// Lives in `core/ui` so adaptive sheets do not import `lib/web/`.
Future<T?> showWebSidePanel<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  double width = 480,
  ThemeData? theme,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      final panelTheme = theme ?? Theme.of(ctx);
      final panelWidth = width
          .clamp(320.0, MediaQuery.sizeOf(ctx).width * 0.9)
          .toDouble();

      // Build the panel (and its stateful [child]) once. AnimatedBuilder
      // reuses this via its `child` argument so TextEditingControllers are
      // not reset on every animation tick.
      final panel = Material(
        color: panelTheme.colorScheme.surface,
        elevation: 16,
        child: SizedBox(
          width: panelWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          color: panelTheme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );

      return Theme(
        data: panelTheme,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(ctx).pop(),
          },
          child: AnimatedBuilder(
            animation: animation,
            child: panel,
            builder: (context, panelChild) {
              final t = Curves.easeOutCubic.transform(animation.value);
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Opacity(
                        opacity: t * 0.54,
                        child: const ColoredBox(color: Colors.black),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset((1 - t) * panelWidth, 0),
                      child: panelChild,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
