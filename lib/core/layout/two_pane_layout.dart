import 'package:flutter/material.dart';

import 'adaptive_scaffold.dart';

class TwoPaneLayout extends StatelessWidget {
  const TwoPaneLayout({
    super.key,
    required this.listPane,
    required this.detailPane,
    this.listWidth = 360,
  });

  final Widget listPane;
  final Widget? detailPane;
  final double listWidth;

  @override
  Widget build(BuildContext context) {
    if (!isWideLayout(context) || detailPane == null) {
      return listPane;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: listWidth, child: listPane),
        const VerticalDivider(width: 1),
        Expanded(child: detailPane!),
      ],
    );
  }
}
