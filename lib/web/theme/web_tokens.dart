import 'package:flutter/material.dart';

/// Premium web design tokens (design-taste variance 8, density 4).
@immutable
class WebTokens extends ThemeExtension<WebTokens> {
  const WebTokens({
    required this.sidebarWidth,
    required this.sidebarCollapsedWidth,
    required this.contentMaxWidth,
    required this.pagePadding,
    required this.bentoRadius,
    required this.diffusionShadow,
    required this.compactBreakpoint,
    required this.desktopBreakpoint,
    required this.wideBreakpoint,
    required this.listPaneWidth,
    required this.wideListPaneWidth,
  });

  final double sidebarWidth;
  final double sidebarCollapsedWidth;
  final double contentMaxWidth;
  final double pagePadding;
  final double bentoRadius;
  final List<BoxShadow> diffusionShadow;
  final double compactBreakpoint;
  final double desktopBreakpoint;
  final double wideBreakpoint;
  final double listPaneWidth;
  final double wideListPaneWidth;

  static const light = WebTokens(
    sidebarWidth: 240,
    sidebarCollapsedWidth: 72,
    contentMaxWidth: 1400,
    pagePadding: 32,
    bentoRadius: 24,
    diffusionShadow: [
      BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 40,
        offset: Offset(0, 20),
        spreadRadius: -15,
      ),
    ],
    compactBreakpoint: 768,
    desktopBreakpoint: 1200,
    wideBreakpoint: 1200,
    listPaneWidth: 360,
    wideListPaneWidth: 400,
  );

  @override
  WebTokens copyWith({
    double? sidebarWidth,
    double? sidebarCollapsedWidth,
    double? contentMaxWidth,
    double? pagePadding,
    double? bentoRadius,
    List<BoxShadow>? diffusionShadow,
    double? compactBreakpoint,
    double? desktopBreakpoint,
    double? wideBreakpoint,
    double? listPaneWidth,
    double? wideListPaneWidth,
  }) {
    return WebTokens(
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      sidebarCollapsedWidth:
          sidebarCollapsedWidth ?? this.sidebarCollapsedWidth,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      pagePadding: pagePadding ?? this.pagePadding,
      bentoRadius: bentoRadius ?? this.bentoRadius,
      diffusionShadow: diffusionShadow ?? this.diffusionShadow,
      compactBreakpoint: compactBreakpoint ?? this.compactBreakpoint,
      desktopBreakpoint: desktopBreakpoint ?? this.desktopBreakpoint,
      wideBreakpoint: wideBreakpoint ?? this.wideBreakpoint,
      listPaneWidth: listPaneWidth ?? this.listPaneWidth,
      wideListPaneWidth: wideListPaneWidth ?? this.wideListPaneWidth,
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
