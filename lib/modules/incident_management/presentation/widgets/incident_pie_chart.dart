import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_dashboard_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class IncidentPieChart extends StatefulWidget {
  const IncidentPieChart({
    required this.title,
    required this.data,
    super.key,
  });

  final String title;
  final Map<String, num> data;

  @override
  State<IncidentPieChart> createState() => _IncidentPieChartState();
}

class _IncidentPieChartState extends State<IncidentPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false);
    final total = entries.fold<num>(0, (sum, entry) => sum + entry.value);

    return IncidentDashboardPanel(
      title: widget.title,
      child: total <= 0
          ? const _ChartEmptyState()
          : Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 54,
                      sections: _sections(context, entries, total),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < entries.length; index++)
                      _LegendItem(
                        color: _chartColor(context, index),
                        label: entries[index].key,
                        value: entries[index].value,
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  List<PieChartSectionData> _sections(
    BuildContext context,
    List<MapEntry<String, num>> entries,
    num total,
  ) {
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final isTouched = index == _touchedIndex;
      final percent = total == 0 ? 0 : (entry.value / total * 100);
      return PieChartSectionData(
        color: _chartColor(context, index),
        value: entry.value.toDouble(),
        title: '${percent.round()}%',
        radius: isTouched ? 72 : 62,
        titleStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      );
    });
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final num value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($value)',
          style: Theme.of(context).textTheme.bodySmall,
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
    scheme.error,
    Colors.deepOrange,
    Colors.amber.shade700,
    Colors.green,
    scheme.primary,
    Colors.teal,
    Colors.indigo,
    Colors.blueGrey,
  ];
  return colors[index % colors.length];
}
