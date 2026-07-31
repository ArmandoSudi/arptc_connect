import 'package:arptc_connect/modules/itsm/changes/application/change_access_policy.dart';
import 'package:arptc_connect/modules/itsm/changes/data/change_repository.dart';
import 'package:arptc_connect/modules/itsm/changes/domain/changes_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('change request queries use one indexed filter dimension', () {
    expect(
      () => ChangeRequestQuery(
        scope: ChangeRequestScope.managerActive,
        type: ChangeType.normal,
        status: ChangeStatus.assessment,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('calendar queries expose every filter without index combinations', () {
    final start = DateTime.utc(2026, 8, 1);
    final end = DateTime.utc(2026, 9, 1);

    for (final query in [
      ChangeCalendarQuery(
        scope: ChangeCalendarScope.operational,
        startsAt: start,
        endsAt: end,
        serviceId: 'service-mail',
      ),
      ChangeCalendarQuery(
        scope: ChangeCalendarScope.operational,
        startsAt: start,
        endsAt: end,
        configurationItemId: 'ci-mail',
      ),
      ChangeCalendarQuery(
        scope: ChangeCalendarScope.operational,
        startsAt: start,
        endsAt: end,
        type: ChangeType.emergency,
      ),
      ChangeCalendarQuery(
        scope: ChangeCalendarScope.operational,
        startsAt: start,
        endsAt: end,
        status: ChangeStatus.scheduled,
      ),
      ChangeCalendarQuery(
        scope: ChangeCalendarScope.operational,
        startsAt: start,
        endsAt: end,
        hasConflict: true,
      ),
    ]) {
      expect(query.endsAt, end);
    }

    expect(
      () => ChangeCalendarQuery(
        scope: ChangeCalendarScope.operational,
        startsAt: start,
        endsAt: end,
        type: ChangeType.normal,
        status: ChangeStatus.scheduled,
      ),
      throwsArgumentError,
    );
  });
}
