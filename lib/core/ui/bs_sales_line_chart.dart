import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../utils/report_range.dart';
import '../../domain/models/sales_period_point.dart';

/// How X-axis labels are formatted for [BsSalesLineChart].
enum SalesChartPeriod { weekly, monthly }

/// Area line chart for sales trends — shared by mobile and web.
class BsSalesLineChart extends StatelessWidget {
  const BsSalesLineChart({
    super.key,
    required this.points,
    this.height = 180,
    this.period = SalesChartPeriod.weekly,
  });

  final List<SalesPeriodPoint> points;
  final double height;
  final SalesChartPeriod period;

  static const _leftAxisWidth = 52.0;
  static const _gridLines = 4;

  String _nptLabel(int index) {
    final npt = points[index].saleDate.toUtc().add(nptOffset);
    if (period == SalesChartPeriod.weekly) {
      return DateFormat.E().format(
        DateTime(npt.year, npt.month, npt.day),
      );
    }
    // Format from NPT calendar fields so locale/timezone can't shift the day.
    return '${npt.month}/${npt.day}';
  }

  List<int> _labelIndices() {
    if (points.isEmpty) return const [];
    if (period == SalesChartPeriod.weekly || points.length <= 8) {
      return [for (var i = 0; i < points.length; i++) i];
    }
    final step = (points.length / 6).ceil().clamp(1, points.length);
    final indices = <int>{0, points.length - 1};
    for (var i = step; i < points.length - 1; i += step) {
      indices.add(i);
    }
    final sorted = indices.toList()..sort();
    return sorted;
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
    final dense = points.length > 10;
    final labelIndices = _labelIndices();
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: BsColors.outline,
      fontSize: 10,
    );

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
                        style: labelStyle,
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
                    showDots: !dense,
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
            child: period == SalesChartPeriod.weekly
                ? Row(
                    children: [
                      for (var i = 0; i < points.length; i++)
                        Expanded(
                          child: Text(
                            _nptLabel(i),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: labelStyle,
                          ),
                        ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      const labelWidth = 36.0;
                      final count = points.length;
                      final last = count - 1;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final i in labelIndices)
                            Positioned(
                              left: () {
                                if (count <= 1) {
                                  return (constraints.maxWidth - labelWidth) /
                                      2;
                                }
                                final center =
                                    (i / last) * constraints.maxWidth;
                                return (center - labelWidth / 2).clamp(
                                  0.0,
                                  constraints.maxWidth - labelWidth,
                                );
                              }(),
                              width: labelWidth,
                              child: Text(
                                _nptLabel(i),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: labelStyle,
                              ),
                            ),
                        ],
                      );
                    },
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
    required this.showDots,
  });

  final List<SalesPeriodPoint> points;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final int gridLines;
  final bool showDots;

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
          ..strokeWidth = showDots ? 2.5 : 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (showDots) {
      for (final c in coords) {
        canvas.drawCircle(c, 4, Paint()..color = lineColor);
        canvas.drawCircle(c, 2, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SalesLinePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.showDots != showDots;
}
