import 'dart:collection';

import '../../shared/domain/itsm_common.dart';
import 'reporting_metrics.dart';

enum ReportSnapshotType {
  operational('operational'),
  executive('executive'),
  incident('incident');

  const ReportSnapshotType(this.value);
  final String value;

  static ReportSnapshotType fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return values.firstWhere(
      (type) => type.value == normalized,
      orElse: () => operational,
    );
  }
}

class ReportHighlight {
  ReportHighlight({
    required this.id,
    required this.reference,
    required this.title,
    required this.type,
    required this.status,
    this.priority,
    this.route,
    Map<String, String> safeLabels = const {},
  }) : safeLabels = UnmodifiableMapView(Map<String, String>.from(safeLabels)) {
    if (id.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('A report highlight requires an ID and title.');
    }
  }

  final String id;
  final String reference;
  final String title;
  final String type;
  final String status;
  final String? priority;
  final String? route;
  final Map<String, String> safeLabels;

  factory ReportHighlight.fromMap(Map<String, Object?> map) => ReportHighlight(
        id: _string(map['id'] ?? map['entityId']),
        reference: _string(map['reference'] ?? map['entityReference']),
        title: _string(map['title'], 'Untitled'),
        type: _string(map['type'] ?? map['entityType'], 'work_item'),
        status: _string(map['status'], 'unknown'),
        priority: _nullableString(map['priority']),
        route: _nullableString(map['route']),
        safeLabels: _stringMap(map['safeLabels']),
      );
}

class ItsmReportSnapshot {
  ItsmReportSnapshot({
    required this.id,
    required this.schemaVersion,
    required this.type,
    required this.audience,
    required this.scopeType,
    required this.scopeId,
    required this.periodGranularity,
    required this.periodKey,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.sourceWatermark,
    required this.isComplete,
    required this.metrics,
    Iterable<ReportHighlight> highlights = const [],
    Map<String, num> sourceCounts = const {},
  })  : highlights = List<ReportHighlight>.unmodifiable(highlights),
        sourceCounts =
            UnmodifiableMapView(Map<String, num>.from(sourceCounts)) {
    if (id.trim().isEmpty || periodKey.trim().isEmpty) {
      throw ArgumentError('Snapshot ID and period key are required.');
    }
    if (audience != ItsmRole.manager && audience != ItsmRole.admin) {
      throw ArgumentError('Reporting snapshots cannot target USER.');
    }
    if (periodEnd.isBefore(periodStart)) {
      throw ArgumentError('Snapshot period end cannot precede its start.');
    }
  }

  final String id;
  final int schemaVersion;
  final ReportSnapshotType type;
  final ItsmRole audience;
  final String scopeType;
  final String scopeId;
  final String periodGranularity;
  final String periodKey;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;
  final DateTime? sourceWatermark;
  final bool isComplete;
  final ReportingMetrics metrics;
  final List<ReportHighlight> highlights;
  final Map<String, num> sourceCounts;

  factory ItsmReportSnapshot.fromMap(String id, Map<String, Object?> map) {
    final audience = ItsmRole.tryParse(map['audience']);
    if (audience == null) {
      throw FormatException('Snapshot $id has no valid audience.');
    }
    final rawBreakdowns = _map(map['breakdowns']);
    final rawTrends = _map(map['trends']);
    return ItsmReportSnapshot(
      id: id,
      schemaVersion: _integer(map['schemaVersion'], 1),
      type: ReportSnapshotType.fromValue(map['snapshotType']),
      audience: audience,
      scopeType: _string(map['scopeType'], 'global'),
      scopeId: _string(map['scopeId'], 'global'),
      periodGranularity: _string(map['periodGranularity'], 'current'),
      periodKey: _string(map['periodKey'], 'current'),
      periodStart: _date(map['periodStart']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      periodEnd: _date(map['periodEnd']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      generatedAt: _date(map['generatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceWatermark: _date(map['sourceWatermark']),
      isComplete: _boolean(map['isComplete']),
      metrics: ReportingMetrics(
        values: _numMap(map['metrics']),
        breakdowns: {
          for (final entry in rawBreakdowns.entries)
            entry.key: _numMap(entry.value),
        },
        trends: {
          for (final entry in rawTrends.entries)
            entry.key: _list(entry.value)
                .map(_map)
                .map((point) => ReportingTrendPoint(
                      label: _string(point['label']),
                      value: _number(point['value']),
                    ))
                .toList(growable: false),
        },
      ),
      highlights: _list(map['highlights'])
          .map(_map)
          .where((item) => item.isNotEmpty)
          .map(ReportHighlight.fromMap),
      sourceCounts: _numMap(map['sourceCounts']),
    );
  }
}

Map<String, Object?> _map(Object? value) => value is Map
    ? value.map((key, item) => MapEntry(key.toString(), item))
    : const {};
List<Object?> _list(Object? value) =>
    value is Iterable ? value.toList() : const [];
String _string(Object? value, [String fallback = '']) =>
    value?.toString().trim().isNotEmpty == true
        ? value.toString().trim()
        : fallback;
String? _nullableString(Object? value) {
  final result = _string(value);
  return result.isEmpty ? null : result;
}

int _integer(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse(_string(value)) ?? fallback;
num _number(Object? value) =>
    value is num ? value : num.tryParse(_string(value)) ?? 0;
bool _boolean(Object? value) =>
    value == true || _string(value).toLowerCase() == 'true';
Map<String, num> _numMap(Object? value) => {
      for (final entry in _map(value).entries) entry.key: _number(entry.value),
    };
Map<String, String> _stringMap(Object? value) => {
      for (final entry in _map(value).entries) entry.key: _string(entry.value),
    };
DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  try {
    final converted = (value as dynamic).toDate();
    return converted is DateTime ? converted : null;
  } on Object {
    return null;
  }
}
