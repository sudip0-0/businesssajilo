import 'package:flutter/material.dart';

/// Shared layout breakpoints — preserve phone / tablet / desktop transitions.
abstract final class BsBreakpoints {
  static const phoneCompact = 480.0;
  static const tablet = 768.0;
  static const tabletWide = 900.0;
  static const desktop = 1024.0;
  static const wide = 1280.0;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isPhoneCompact(BuildContext context) =>
      widthOf(context) < phoneCompact;

  static bool isTabletOrWider(BuildContext context) =>
      widthOf(context) >= tablet;

  static bool isTabletWideOrWider(BuildContext context) =>
      widthOf(context) >= tabletWide;

  static bool isDesktopOrWider(BuildContext context) =>
      widthOf(context) >= desktop;

  static bool isWideOrWider(BuildContext context) => widthOf(context) >= wide;
}
