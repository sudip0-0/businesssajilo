import 'package:flutter/material.dart';

import '../layout/web_content_frame.dart';
import '../layout/web_page_header.dart';

/// Standard web page chrome: content frame + header + body.
class WebPageScaffold extends StatelessWidget {
  const WebPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs = const [],
    this.actions = const [],
    required this.body,
    this.fillHeight = true,
  });

  final String title;
  final String? subtitle;
  final List<String> breadcrumbs;
  final List<Widget> actions;
  final Widget body;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return WebContentFrame(
      fillHeight: fillHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebPageHeader(
            title: title,
            subtitle: subtitle,
            breadcrumbs: breadcrumbs,
            actions: actions,
          ),
          if (fillHeight) Expanded(child: body) else body,
        ],
      ),
    );
  }
}
