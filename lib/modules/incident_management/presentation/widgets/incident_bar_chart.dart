import 'dart:math' as math;

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_dashboard_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class IncidentBarChart extends StatelessWidget {
  const IncidentBarChart({
    required this.title,
    required this.data,
    this.orientation = IncidentBarChartOrientation.vertical,
    super.key,
  });

  final String title;
  final Map<String, num> data;
  final IncidentBarChartOrientation orientation;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList(growable: false);
    final total = entries.fold<num>(0, (sum, entry) => sum + entry.value);

    return IncidentDashboardPanel(
      title: title,
      child: total <= 0
          ? const _ChartEmptyState()
          : orientation == IncidentBarChartOrientation.horizontal
              ? _HorizontalBars(entries: entries)
              : _VerticalBars(entries: entries),
    );
  }
}

enum IncidentBarChartOrientation { vertical, horizontal }

class _VerticalBars extends StatelessWidget {
  const _VerticalBars({required this.entries});

  final List<MapEntry<String, num>> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = entries.fold<num>(0, (max, entry) {
      return entry.value > max ? entry.value : max;
    }).toDouble();
    final maxY = math.max(4, (maxValue * 1.25).ceil()).toDouble();
    final interval = math.max(1, (maxY / 4).ceil()).toDouble();

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: theme.colorScheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = entries[group.x.toInt()].key;
                return BarTooltipItem(
                  '$label\n${rod.toY.round()}',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                  ),
                );
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
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: SizedBox(
                      width: 68,
                      child: Text(
                        _shortLabel(entries[index].key),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < entries.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: entries[index].value.toDouble(),
                    color: _chartColor(context, index),
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalBars extends StatelessWidget {
  const _HorizontalBars({required this.entries});

  final List<MapEntry<String, num>> entries;

  @override
  Widget build(BuildContext context) {
    final maxValue = entries.fold<num>(0, (max, entry) {
      return entry.value > max ? entry.value : max;
    }).toDouble();

    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          _HorizontalBarRow(
            color: _chartColor(context, index),
            label: entries[index].key,
            value: entries[index].value,
            maxValue: maxValue,
          ),
          if (index != entries.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HorizontalBarRow extends StatelessWidget {
  const _HorizontalBarRow({
    required this.color,
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final Color color;
  final String label;
  final num value;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final factor = maxValue == 0 ? 0.0 : value / maxValue;

    return Row(
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                FractionallySizedBox(
                  widthFactor: factor.clamp(0.0, 1.0).toDouble(),
                  child: Container(
                    height: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 34,
          child: Text(
            value.toString(),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
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

Color _chartColor(BuildContext context, int index) {
  final scheme = Theme.of(context).colorScheme;
  final colors = [
    scheme.primary,
    Colors.teal,
    Colors.orange,
    Colors.deepOrange,
    scheme.error,
    Colors.indigo,
    Colors.green,
    Colors.blueGrey,
    Colors.cyan,
    Colors.brown,
    Colors.pink,
  ];
  return colors[index % colors.length];
}

String _shortLabel(String label) {
  if (label.length <= 16) {
    return label;
  }
  return '${label.substring(0, 15)}...';
}
