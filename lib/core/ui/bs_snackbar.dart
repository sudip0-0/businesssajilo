import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Floating snackbar capped for wide web layouts.
SnackBar bsSnackBar(
  BuildContext context, {
  required String message,
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  final maxWidth = math.min(420.0, MediaQuery.sizeOf(context).width - 32);
  return SnackBar(
    content: Text(message),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.floating,
    width: maxWidth,
    action: action,
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
