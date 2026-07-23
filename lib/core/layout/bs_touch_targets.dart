import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bs_breakpoints.dart';

/// Minimum interactive target sizes per platform guidance.
abstract final class BsTouchTargets {
  static const mobileMin = 48.0;
  static const webPointerMin = 40.0;
  static const webTouchCompactMin = 44.0;

  /// Minimum tap/pointer target for [context].
  static double minFor(BuildContext context) {
    if (!kIsWeb) return mobileMin;
    if (BsBreakpoints.widthOf(context) < BsBreakpoints.tabletWide) {
      return webTouchCompactMin;
    }
    return webPointerMin;
  }

  /// Wraps [child] so its hit area meets [minFor] without changing layout size.
  static Widget ensureMin({
    required BuildContext context,
    required Widget child,
    double? minSize,
  }) {
    final min = minSize ?? minFor(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: min, minHeight: min),
      child: child,
    );
  }
}
