import 'package:flutter/material.dart';

import '../../core/ui/web_side_panel.dart' as core;
import '../theme/web_theme.dart';

/// Web-themed wrapper around the shared side panel in `core/ui`.
Future<T?> showWebSidePanel<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  double width = 480,
}) {
  return core.showWebSidePanel<T>(
    context: context,
    title: title,
    width: width,
    theme: WebTheme.light(),
    child: child,
  );
}
