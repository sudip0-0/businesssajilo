import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/sales_period_point.dart';

/// Area line chart for dashboard sales trends (no external chart dependency).
class WebSalesLineChart extends StatelessWidget {
  const WebSalesLineChart({
    super.key,
    required this.points,
    this.height = 200,
  });

  final List<SalesPeriodPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '—',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BsColors.outline,
                ),
          ),
        ),
      );
    }

    final maxSales = points
        .map((p) => p.totalSales)
        .fold<int>(0, (m, v) => v > m ? v : m);
    final effectiveMax = maxSales == 0 ? 1 : maxSales;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _SalesLinePainter(
              points: points,
              maxValue: effectiveMax.toDouble(),
              lineColor: BsColors.primary,
              fillColor: BsColors.primary.withValues(alpha: 0.08),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final point in points)
              Expanded(
                child: Text(
                  DateFormat.E().format(point.saleDate),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: BsColors.outline,
                      ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SalesLinePainter extends CustomPainter {
  _SalesLinePainter({
    required this.points,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
  });

  final List<SalesPeriodPoint> points;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final dx = size.width / math.max(points.length - 1, 1);
    final coords = <Offset>[];

    for (var i = 0; i < points.length; i++) {
      final y = size.height - (points[i].totalSales / maxValue) * size.height;
      coords.add(Offset(i * dx, y.clamp(0, size.height)));
    }

    final fillPath = Path()..moveTo(coords.first.dx, size.height);
    for (final c in coords) {
      fillPath.lineTo(c.dx, c.dy);
    }
    fillPath
      ..lineTo(coords.last.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);

    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (var i = 1; i < coords.length; i++) {
      linePath.lineTo(coords[i].dx, coords[i].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final c in coords) {
      canvas.drawCircle(c, 4, Paint()..color = lineColor);
      canvas.drawCircle(c, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SalesLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.maxValue != maxValue;
}
