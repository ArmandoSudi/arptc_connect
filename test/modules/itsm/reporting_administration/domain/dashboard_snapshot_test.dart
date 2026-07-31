import 'package:arptc_connect/modules/itsm/reporting_administration/domain/reporting_administration_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a trusted operational snapshot without raw work items', () {
    final snapshot = ItsmReportSnapshot.fromMap('manager-current', {
      'schemaVersion': 2,
      'snapshotType': 'operational',
      'audience': 'MANAGER',
      'scopeType': 'global',
      'scopeId': 'global',
      'periodGranularity': 'current',
      'periodKey': 'current',
      'periodStart': '2026-07-01T00:00:00Z',
      'periodEnd': '2026-07-31T23:59:59Z',
      'generatedAt': '2026-07-31T10:00:00Z',
      'isComplete': true,
      'metrics': {'openIncidents': 12, 'slaBreached': 2},
      'breakdowns': {
        'incidentsByPriority': {'P1': 1, 'P2': 3},
      },
      'trends': {
        'sixMonthTrend': [
          {'label': 'Jul', 'value': 12},
        ],
      },
      'highlights': [
        {
          'id': 'incident-1',
          'reference': 'INC-1',
          'title': 'Mail unavailable',
          'type': 'incident',
          'status': 'open',
        }
      ],
    });

    expect(snapshot.audience, ItsmRole.manager);
    expect(snapshot.type, ReportSnapshotType.operational);
    expect(snapshot.metrics.metric('openIncidents'), 12);
    expect(snapshot.metrics.breakdown('incidentsByPriority')['P2'], 3);
    expect(snapshot.metrics.trend('sixMonthTrend').single.label, 'Jul');
    expect(snapshot.highlights.single.reference, 'INC-1');
  });

  test('rejects USER reporting snapshots', () {
    expect(
      () => ItsmReportSnapshot(
        id: 'invalid',
        schemaVersion: 1,
        type: ReportSnapshotType.operational,
        audience: ItsmRole.user,
        scopeType: 'global',
        scopeId: 'global',
        periodGranularity: 'current',
        periodKey: 'current',
        periodStart: DateTime.utc(2026, 7, 1),
        periodEnd: DateTime.utc(2026, 7, 31),
        generatedAt: DateTime.utc(2026, 7, 31),
        sourceWatermark: null,
        isComplete: true,
        metrics: ReportingMetrics(),
      ),
      throwsArgumentError,
    );
  });
}
