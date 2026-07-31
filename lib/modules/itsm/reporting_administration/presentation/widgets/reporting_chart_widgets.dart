import 'package:flutter/material.dart';

import '../../domain/reporting_metrics.dart';
import '../reporting_administration_strings.dart';
import 'reporting_page_shell.dart';

class ReportingBreakdownChart extends StatelessWidget {
  const ReportingBreakdownChart(
      {required this.title, required this.data, super.key});
  final String title;
  final Map<String, num> data;

  @override
  Widget build(BuildContext context) {
    final maximum =
        data.values.fold<num>(0, (max, value) => value > max ? value : max);
    return ReportingPanel(
      title: title,
      child: data.isEmpty
          ? Text(ReportingAdministrationStrings.of(context).value('noData'))
          : Column(
              children: data.entries.map((entry) {
                final fraction = maximum == 0 ? 0.0 : entry.value / maximum;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 110,
                          child:
                              Text(entry.key, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: LinearProgressIndicator(
                              value: fraction.toDouble(),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(width: 10),
                      Text('${entry.value}'),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class ReportingTrendChart extends StatelessWidget {
  const ReportingTrendChart(
      {required this.title, required this.points, super.key});
  final String title;
  final List<ReportingTrendPoint> points;

  @override
  Widget build(BuildContext context) => ReportingPanel(
        title: title,
        child: points.isEmpty
            ? Text(ReportingAdministrationStrings.of(context).value('noData'))
            : SizedBox(
                height: 160,
                child: LayoutBuilder(builder: (context, constraints) {
                  final max = points.map((point) => point.value).fold<num>(
                      0, (left, right) => right > left ? right : left);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: points.map((point) {
                      final height = max == 0 ? 4.0 : 110 * point.value / max;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${point.value}'),
                              Container(
                                  height: height.toDouble(),
                                  decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6)))),
                              const SizedBox(height: 4),
                              Text(point.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  );
                }),
              ),
      );
}
