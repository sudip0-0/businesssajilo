import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Corporate web design tokens per Design.md.
@immutable
class WebTokens extends ThemeExtension<WebTokens> {
  const WebTokens({
    required this.sidebarWidth,
    required this.sidebarCollapsedWidth,
    required this.contentMaxWidth,
    required this.pagePadding,
    required this.gutter,
    required this.cardRadius,
    required this.inputRadius,
    required this.metricShadow,
    required this.modalShadow,
    required this.compactBreakpoint,
    required this.desktopBreakpoint,
    required this.wideBreakpoint,
    required this.listPaneWidth,
    required this.wideListPaneWidth,
    required this.buttonHeight,
    required this.buttonHeightCompact,
    required this.topBarHeight,
  });

  final double sidebarWidth;
  final double sidebarCollapsedWidth;
  final double contentMaxWidth;
  final double pagePadding;
  final double gutter;
  final double cardRadius;
  final double inputRadius;
  final List<BoxShadow> metricShadow;
  final List<BoxShadow> modalShadow;
  final double compactBreakpoint;
  final double desktopBreakpoint;
  final double wideBreakpoint;
  final double listPaneWidth;
  final double wideListPaneWidth;
  final double buttonHeight;
  final double buttonHeightCompact;
  final double topBarHeight;

  static const light = WebTokens(
    sidebarWidth: 260,
    sidebarCollapsedWidth: 64,
    contentMaxWidth: 1280,
    pagePadding: 24,
    gutter: 16,
    cardRadius: BsRadii.lg,
    inputRadius: BsRadii.md,
    metricShadow: BsElevation.level2,
    modalShadow: BsElevation.level3,
    compactBreakpoint: 768,
    desktopBreakpoint: 1024,
    wideBreakpoint: 1280,
    listPaneWidth: 360,
    wideListPaneWidth: 400,
    buttonHeight: 40,
    buttonHeightCompact: 32,
    topBarHeight: 56,
  );

  @override
  WebTokens copyWith({
    double? sidebarWidth,
    double? sidebarCollapsedWidth,
    double? contentMaxWidth,
    double? pagePadding,
    double? gutter,
    double? cardRadius,
    double? inputRadius,
    List<BoxShadow>? metricShadow,
    List<BoxShadow>? modalShadow,
    double? compactBreakpoint,
    double? desktopBreakpoint,
    double? wideBreakpoint,
    double? listPaneWidth,
    double? wideListPaneWidth,
    double? buttonHeight,
    double? buttonHeightCompact,
    double? topBarHeight,
  }) {
    return WebTokens(
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      sidebarCollapsedWidth:
          sidebarCollapsedWidth ?? this.sidebarCollapsedWidth,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      pagePadding: pagePadding ?? this.pagePadding,
      gutter: gutter ?? this.gutter,
      cardRadius: cardRadius ?? this.cardRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      metricShadow: metricShadow ?? this.metricShadow,
      modalShadow: modalShadow ?? this.modalShadow,
      compactBreakpoint: compactBreakpoint ?? this.compactBreakpoint,
      desktopBreakpoint: desktopBreakpoint ?? this.desktopBreakpoint,
      wideBreakpoint: wideBreakpoint ?? this.wideBreakpoint,
      listPaneWidth: listPaneWidth ?? this.listPaneWidth,
      wideListPaneWidth: wideListPaneWidth ?? this.wideListPaneWidth,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      buttonHeightCompact: buttonHeightCompact ?? this.buttonHeightCompact,
      topBarHeight: topBarHeight ?? this.topBarHeight,
    );
  }

  @override
  WebTokens lerp(ThemeExtension<WebTokens>? other, double t) {
    if (other is! WebTokens) return this;
    return this;
  }
}

extension WebTokensX on BuildContext {
  WebTokens get webTokens =>
      Theme.of(this).extension<WebTokens>() ?? WebTokens.light;

  bool get isWebCompact =>
      MediaQuery.sizeOf(this).width < webTokens.compactBreakpoint;

  bool get isWebWide =>
      MediaQuery.sizeOf(this).width >= webTokens.wideBreakpoint;
}
