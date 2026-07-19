import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme/web_palette.dart';

/// Subtle paper grain that sits above the scaffold canvas and breaks the
/// digital flatness of large paper surfaces. Purely decorative.
class WebPaperGrain extends StatelessWidget {
  const WebPaperGrain({super.key, this.opacity = 0.5});

  /// Overall strength of the speckle (0–1 multiplier).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GrainPainter(opacity: opacity),
        size: Size.infinite,
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;
    // Deterministic low-density speckle: two interleaved lattices of
    // 1px dots, one ink, one warm-white, like laid paper.
    final random = math.Random(20260718);
    final count = (size.width * size.height / 2400).round();
    for (var i = 0; i < count; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final dark = random.nextBool();
      paint.color =
          (dark ? WebPalette.ink : Colors.white).withValues(
            alpha: (dark ? 0.028 : 0.35) * opacity,
          );
      canvas.drawPoints(PointMode.points, [Offset(dx, dy)], paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

/// Fine ledger rules — horizontal account-book lines with a vertical
/// margin rule. Used on the authentication brand panel.
class LedgerLinesPainter extends CustomPainter {
  const LedgerLinesPainter({this.color = const Color(0x0FFFFFFF)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const rowHeight = 34.0;
    for (var y = rowHeight; y < size.height; y += rowHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Margin rules — the classic double vertical of a ledger page.
    const margin = 88.0;
    if (size.width > margin + 40) {
      canvas.drawLine(
        const Offset(margin, 0),
        Offset(margin, size.height),
        linePaint,
      );
      canvas.drawLine(
        const Offset(margin + 5, 0),
        Offset(margin + 5, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(LedgerLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}
