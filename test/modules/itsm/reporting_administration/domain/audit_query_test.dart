import 'package:arptc_connect/modules/itsm/reporting_administration/domain/reporting_administration_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interactive audit query is bounded and accepts one equality filter',
      () {
    final query = AuditQuery(
      from: DateTime.utc(2026, 7, 1),
      to: DateTime.utc(2026, 7, 31),
      dimension: AuditEqualityDimension.module,
      value: 'support',
    );
    expect(query.toPrimitiveMap()['dimension'], 'module');
    expect(
      () => AuditQuery(
        from: DateTime.utc(2026, 1, 1),
        to: DateTime.utc(2026, 7, 31),
      ),
      throwsArgumentError,
    );
    expect(
      () => AuditQuery(
        from: DateTime.utc(2026, 7, 1),
        to: DateTime.utc(2026, 7, 2),
        dimension: AuditEqualityDimension.module,
      ),
      throwsArgumentError,
    );
  });

  test('compatibility adapter reads canonical and historical aliases', () {
    final event = GlobalAuditEvent.fromMap('event-1', {
      'action': 'incident.closed',
      'module': 'support',
      'targetEntityType': 'incident',
      'targetEntityId': 'incident-1',
      'targetReference': 'INC-1',
      'actorUserId': 'manager-1',
      'actorDisplayName': 'Manager',
      'previousValues': {'status': 'resolved'},
      'newValues': {'status': 'closed'},
      'occurredAt': '2026-07-31T10:00:00Z',
      'isRestricted': false,
    });
    expect(event.entityType, 'incident');
    expect(event.before['status'], 'resolved');
    expect(event.after['status'], 'closed');
    expect(event.canBeReadBy(role: ItsmRole.admin, userId: 'admin-1'), isTrue);
  });

  test('restricted events are manager-authorized and hidden from ADMIN', () {
    final event = GlobalAuditEvent.fromMap('event-2', {
      'action': 'finding.updated',
      'module': 'security',
      'entityType': 'security_finding',
      'entityId': 'finding-1',
      'actor': {'userId': 'manager-1'},
      'createdAt': '2026-07-31T10:00:00Z',
      'isRestricted': true,
      'authorizedManagerIds': ['manager-2'],
    });
    expect(
        event.canBeReadBy(role: ItsmRole.manager, userId: 'manager-2'), isTrue);
    expect(event.canBeReadBy(role: ItsmRole.manager, userId: 'manager-1'),
        isFalse);
    expect(event.canBeReadBy(role: ItsmRole.admin, userId: 'admin-1'), isFalse);
  });
}
