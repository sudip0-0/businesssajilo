import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui/money_text.dart';
import '../../core/utils/money.dart';
import '../../domain/models/sales_period_point.dart';

class SalesBarChart extends StatelessWidget {
  const SalesBarChart({super.key, required this.points});

  final List<SalesPeriodPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxSales = points
        .map((p) => p.totalSales)
        .fold<int>(0, (m, v) => v > m ? v : m);
    final effectiveMax = maxSales == 0 ? 1 : maxSales;

    return Column(
      children: points.map((point) {
        final fraction = point.totalSales / effectiveMax;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  '${point.saleDate.day}/${point.saleDate.month}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 20,
                    backgroundColor: BsColors.primary.withValues(alpha: 0.1),
                    color: BsColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MoneyText(Paisa(point.totalSales), showPaisa: false),
            ],
          ),
        );
      }).toList(),
    );
  }
}
