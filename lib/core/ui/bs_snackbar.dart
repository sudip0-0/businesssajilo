import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Floating toast capped for wide web layouts.
///
/// Uses a transparent full-width [SnackBar] shell with a constrained inner
/// card. Flutter's [SnackBar.width] is unreliable on Material 3 / web and
/// often falls back to near full-bleed inset padding.
SnackBar bsSnackBar(
  BuildContext context, {
  required String message,
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  final theme = Theme.of(context);
  final snackTheme = theme.snackBarTheme;
  final bg =
      backgroundColor ??
      snackTheme.backgroundColor ??
      theme.colorScheme.inverseSurface;
  final fg =
      snackTheme.contentTextStyle?.color ??
      theme.colorScheme.onInverseSurface;
  final maxWidth = math.min(420.0, MediaQuery.sizeOf(context).width - 32);

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    content: Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: bg,
          elevation: 4,
          shadowColor: Colors.black26,
          shape:
              snackTheme.shape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: DefaultTextStyle(
                    style:
                        snackTheme.contentTextStyle ??
                        theme.textTheme.bodyMedium!.copyWith(color: fg),
                    child: Text(message),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      action.onPressed.call();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor:
                          snackTheme.actionTextColor ??
                          theme.colorScheme.inversePrimary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(action.label),
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

/// Shows a [bsSnackBar] via the nearest [ScaffoldMessenger].
void showBsSnackBar(
  BuildContext context, {
  required String message,
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    bsSnackBar(
      context,
      message: message,
      backgroundColor: backgroundColor,
      action: action,
    ),
  );
}

/// Like [showBsSnackBar] when only a [ScaffoldMessengerState] is available.
void showBsSnackBarOn(
  ScaffoldMessengerState messenger, {
  required BuildContext context,
  required String message,
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  messenger.showSnackBar(
    bsSnackBar(
      context,
      message: message,
      backgroundColor: backgroundColor,
      action: action,
    ),
  );
}
