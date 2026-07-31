import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/dashboard_snapshot.dart';
import 'reporting_chart_widgets.dart';
import 'reporting_kpi_card.dart';
import 'reporting_page_shell.dart';
import '../reporting_administration_strings.dart';

class ReportingDashboardLayout extends StatelessWidget {
  const ReportingDashboardLayout({required this.snapshot, super.key});
  final ItsmReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final metrics = snapshot.metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!snapshot.isComplete)
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.sync_problem_rounded),
              title: Text(strings.value('incompleteSnapshot')),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            '${strings.value('generatedAt')} '
            '${DateFormat.yMMMd().add_Hm().format(snapshot.generatedAt.toLocal())}',
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 4
              : constraints.maxWidth >= 640
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics.values.entries
                .take(8)
                .map((entry) => SizedBox(
                      width: width,
                      child: ReportingKpiCard(
                          label: _humanize(entry.key),
                          value: entry.value,
                          icon: _metricIcon(entry.key)),
                    ))
                .toList(growable: false),
          );
        }),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth >= 900
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ...metrics.breakdowns.entries.map((entry) => SizedBox(
                  width: width,
                  child: ReportingBreakdownChart(
                      title: _humanize(entry.key), data: entry.value))),
              ...metrics.trends.entries.map((entry) => SizedBox(
                  width: width,
                  child: ReportingTrendChart(
                      title: _humanize(entry.key), points: entry.value))),
            ],
          );
        }),
        if (snapshot.highlights.isNotEmpty) ...[
          const SizedBox(height: 20),
          ReportingPanel(
            title: strings.value('highlights'),
            child: Column(
              children: snapshot.highlights
                  .map((item) => ListTile(
                        leading: const Icon(Icons.bolt_rounded),
                        title: Text(item.title),
                        subtitle: Text([item.reference, item.status]
                            .where((value) => value.isNotEmpty)
                            .join(' • ')),
                        trailing: item.priority == null
                            ? null
                            : Chip(label: Text(item.priority!)),
                      ))
                  .toList(growable: false),
            ),
          ),
        ],
      ],
    );
  }
}

String _humanize(String value) => value
    .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
    .replaceAll('_', ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

IconData _metricIcon(String key) {
  final normalized = key.toLowerCase();
  if (normalized.contains('sla') || normalized.contains('breach')) {
    return Icons.timer_outlined;
  }
  if (normalized.contains('asset') || normalized.contains('stock')) {
    return Icons.inventory_2_outlined;
  }
  if (normalized.contains('change')) {
    return Icons.change_circle_outlined;
  }
  if (normalized.contains('security') || normalized.contains('finding')) {
    return Icons.shield_outlined;
  }
  return Icons.analytics_outlined;
}
