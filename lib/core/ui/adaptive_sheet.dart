import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'web_side_panel.dart';

/// Shows a bottom sheet on mobile and a right side panel on web.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isScrollControlled = true,
  double webPanelWidth = 480,
}) {
  if (kIsWeb) {
    return showWebSidePanel<T>(
      context: context,
      title: title,
      width: webPanelWidth,
      child: child,
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (_) => child,
  );
}
