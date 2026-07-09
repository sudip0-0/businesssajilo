import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../../domain/models/sales_period_point.dart';

/// Area line chart for sales trends — shared by mobile and web.
class BsSalesLineChart extends StatelessWidget {
  const BsSalesLineChart({super.key, required this.points, this.height = 180});

  final List<SalesPeriodPoint> points;
  final double height;

  static const _leftAxisWidth = 52.0;
  static const _gridLines = 4;

  String _labelForPoint(List<SalesPeriodPoint> points, int index) {
    if (points.length <= 7) {
      return DateFormat.E().format(points[index].saleDate);
    }
    final step = (points.length / 7).ceil();
    final isFirst = index == 0;
    final isLast = index == points.length - 1;
    final isStep = index % step == 0;
    if (isFirst || isLast || isStep) {
      return DateFormat.E().format(points[index].saleDate);
    }
    return '';
  }

  String _formatAxisValue(int value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(value >= 1000000 ? 0 : 1)}L';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '—',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BsColors.outline),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _leftAxisWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = _gridLines; i >= 0; i--)
                      Text(
                        _formatAxisValue(
                          (effectiveMax * i / _gridLines).round(),
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: BsColors.outline,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  painter: _SalesLinePainter(
                    points: points,
                    maxValue: effectiveMax.toDouble(),
                    lineColor: BsColors.primary,
                    fillColor: BsColors.primary.withValues(alpha: 0.08),
                    gridLines: _gridLines,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: _leftAxisWidth + 8),
          child: SizedBox(
            height: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < points.length; i++)
                  Expanded(
                    child: Text(
                      _labelForPoint(points, i),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: BsColors.outline,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
    required this.gridLines,
  });

  final List<SalesPeriodPoint> points;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final int gridLines;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = BsColors.border
      ..strokeWidth = 1;

    for (var i = 0; i <= gridLines; i++) {
      final y = size.height * i / gridLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final count = points.length;
    final dx = count <= 1 ? size.width : size.width / (count - 1);
    final coords = <Offset>[];

    for (var i = 0; i < count; i++) {
      final x = count <= 1 ? size.width / 2 : i * dx;
      final y =
          size.height - (points[i].totalSales / maxValue) * size.height * 0.92;
      coords.add(Offset(x, y.clamp(0, size.height)));
    }

    if (coords.length >= 2) {
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
    }

    for (final c in coords) {
      canvas.drawCircle(c, 4, Paint()..color = lineColor);
      canvas.drawCircle(c, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SalesLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.maxValue != maxValue;
}
