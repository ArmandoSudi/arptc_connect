import 'package:arptc_connect/modules/itsm/changes/domain/changes_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChangeCalendarConflictDetector', () {
    test('detects overlapping changes sharing services, CIs and assets', () {
      final conflicts = ChangeCalendarConflictDetector.detect([
        _entry(
          id: 'change-1',
          startHour: 10,
          endHour: 12,
          services: const ['service-1'],
          cis: const ['ci-1'],
          assets: const ['asset-1'],
        ),
        _entry(
          id: 'change-2',
          startHour: 11,
          endHour: 13,
          services: const ['service-1'],
          cis: const ['ci-1'],
          assets: const ['asset-1'],
        ),
      ]);

      expect(conflicts, hasLength(1));
      expect(
        conflicts.single.kinds,
        containsAll(ChangeCalendarConflictKind.values),
      );
      expect(
        conflicts.single.sharedResourceIds,
        containsAll(['service-1', 'ci-1', 'asset-1']),
      );
    });

    test('does not flag adjacent windows or unrelated resources', () {
      final conflicts = ChangeCalendarConflictDetector.detect([
        _entry(
          id: 'change-1',
          startHour: 10,
          endHour: 11,
          services: const ['service-1'],
        ),
        _entry(
          id: 'change-2',
          startHour: 11,
          endHour: 12,
          services: const ['service-1'],
        ),
        _entry(
          id: 'change-3',
          startHour: 10,
          endHour: 11,
          services: const ['service-2'],
        ),
      ]);

      expect(conflicts, isEmpty);
    });

    test('ignores cancelled, rejected and closed entries', () {
      final conflicts = ChangeCalendarConflictDetector.detect([
        _entry(
          id: 'active',
          startHour: 10,
          endHour: 12,
          services: const ['service-1'],
        ),
        for (final status in [
          ChangeStatus.cancelled,
          ChangeStatus.rejected,
          ChangeStatus.closed,
        ])
          _entry(
            id: status.value,
            startHour: 10,
            endHour: 12,
            services: const ['service-1'],
            status: status,
          ),
      ]);

      expect(conflicts, isEmpty);
    });

    test('round-trips a bounded calendar projection', () {
      final source = _entry(
        id: 'change-1',
        startHour: 10,
        endHour: 12,
        services: const ['service-1'],
      );
      final parsed = ChangeCalendarEntry.fromMap(
        source.changeId,
        source.toFirestore(),
      );

      expect(parsed.window.startsAt, DateTime.utc(2026, 8, 1, 10));
      expect(parsed.affectedServiceIds, {'service-1'});
      expect(
          () => parsed.affectedServiceIds.add('other'), throwsUnsupportedError);
    });
  });
}

ChangeCalendarEntry _entry({
  required String id,
  required int startHour,
  required int endHour,
  ChangeStatus status = ChangeStatus.scheduled,
  List<String> services = const [],
  List<String> cis = const [],
  List<String> assets = const [],
}) {
  return ChangeCalendarEntry(
    changeId: id,
    changeNumber: 'CHG-$id',
    title: 'Calendar change $id',
    type: ChangeType.normal,
    status: status,
    risk: ChangeRiskLevel.medium,
    requesterUserId: 'requester-1',
    window: ChangeWindow(
      startsAt: DateTime.utc(2026, 8, 1, startHour),
      endsAt: DateTime.utc(2026, 8, 1, endHour),
    ),
    maintenancePublished: true,
    affectedServiceIds: services,
    affectedCiIds: cis,
    affectedAssetIds: assets,
  );
}
