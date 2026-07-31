import 'dart:collection';

class ReportingTrendPoint {
  const ReportingTrendPoint({required this.label, required this.value});

  final String label;
  final num value;
}

class ReportingMetrics {
  ReportingMetrics({
    Map<String, num> values = const {},
    Map<String, Map<String, num>> breakdowns = const {},
    Map<String, List<ReportingTrendPoint>> trends = const {},
  })  : values = UnmodifiableMapView(Map<String, num>.from(values)),
        breakdowns = UnmodifiableMapView({
          for (final entry in breakdowns.entries)
            entry.key: UnmodifiableMapView(Map<String, num>.from(entry.value)),
        }),
        trends = UnmodifiableMapView({
          for (final entry in trends.entries)
            entry.key: List<ReportingTrendPoint>.unmodifiable(entry.value),
        });

  final Map<String, num> values;
  final Map<String, Map<String, num>> breakdowns;
  final Map<String, List<ReportingTrendPoint>> trends;

  num metric(String key) => values[key] ?? 0;

  Map<String, num> breakdown(String key) => breakdowns[key] ?? const {};

  List<ReportingTrendPoint> trend(String key) => trends[key] ?? const [];
}
