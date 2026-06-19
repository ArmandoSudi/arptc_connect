import 'dart:math' as math;

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_dashboard_stats.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_dashboard_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class IncidentLineChart extends StatelessWidget {
  const IncidentLineChart({
    required this.title,
    required this.points,
    super.key,
  });

  final String title;
  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final total = points.fold<num>(0, (sum, point) => sum + point.value);

    return IncidentDashboardPanel(
      title: title,
      child: total <= 0
          ? const _ChartEmptyState()
          : SizedBox(
              height: 280,
              child: LineChart(_chartData(context)),
            ),
    );
  }

  LineChartData _chartData(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxValue = points.fold<num>(0, (max, point) {
      return point.value > max ? point.value : max;
    }).toDouble();
    final maxY = math.max(4, (maxValue * 1.25).ceil()).toDouble();
    final interval = math.max(1, (maxY / 4).ceil()).toDouble();

    return LineChartData(
      minX: 0,
      maxX: math.max(0, points.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: scheme.inverseSurface,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final index = spot.x.toInt();
              final label = index >= 0 && index < points.length
                  ? points[index].label
                  : '';
              return LineTooltipItem(
                '$label\n${spot.y.round()}',
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList();
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  value.round().toString(),
                  style: theme.textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(
                  points[index].label,
                  style: theme.textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          color: scheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: scheme.primary,
                strokeWidth: 2,
                strokeColor: scheme.surface,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: scheme.primary.withOpacity(0.12),
          ),
          spots: [
            for (var index = 0; index < points.length; index++)
              FlSpot(index.toDouble(), points[index].value.toDouble()),
          ],
        ),
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Text(
          S.of(context).dashboardDataDoesNotExist,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
