import 'package:arptc_connect/modules/itsm/shared/data/firestore_itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItsmWorkItemIndexMapper', () {
    test('maps a complete service-request summary', () {
      final item = ItsmWorkItemIndexMapper.fromMap(
        'service_request:request-1',
        {
          'id': 'request-1',
          'type': 'service_request',
          'reference': 'REQ-2026-001',
          'title': 'New laptop',
          'description': 'Replacement equipment',
          'requesterId': 'agent-1',
          'affectedUserId': 'agent-1',
          'serviceId': 'end-user-computing',
          'assignedUserId': 'manager-1',
          'priority': 'P3',
          'status': 'in_fulfilment',
          'lifecycleState': 'active',
          'workflowDefinitionId': 'standard-request',
          'workflowVersion': 3,
          'createdAt': '2026-07-01T08:00:00Z',
          'createdBy': 'agent-1',
          'updatedAt': '2026-07-02T09:00:00Z',
          'updatedBy': 'manager-1',
          'dueAt': '2026-07-05T08:00:00Z',
          'confidentiality': 'internal',
          'linkedAssetIds': ['asset-1'],
        },
      );

      expect(item.id, 'request-1');
      expect(item.type, ItsmWorkItemType.serviceRequest);
      expect(item.priority, ItsmPriority.p3);
      expect(item.workflowVersion, 3);
      expect(item.assignedUserId, 'manager-1');
      expect(item.linkedAssetIds, ['asset-1']);
      expect(item.dueAt, DateTime.utc(2026, 7, 5, 8));
    });

    test('adapts additive and legacy fields without losing ownership', () {
      final item = ItsmWorkItemIndexMapper.fromMap(
        'incident:incident-9',
        {
          'type': 'incident',
          'ticketNumber': 'INC-9',
          'title': 'Network unavailable',
          'affectedUserId': 'agent-9',
          'createdByUserId': 'agent-8',
          'status': 'open',
          'createdAt': DateTime.utc(2026, 7, 3),
          'confidentiality': 'INTERNAL',
        },
      );

      expect(item.id, 'incident-9');
      expect(item.reference, 'INC-9');
      expect(item.requesterId, 'agent-9');
      expect(item.createdBy, 'agent-8');
      expect(item.lifecycleState, ItsmLifecycleState.active);
      expect(item.confidentiality, ItsmConfidentiality.internal);
    });

    test('rejects an unsupported work-item type', () {
      expect(
        () => ItsmWorkItemIndexMapper.fromMap(
          'unknown:1',
          {
            'type': 'problem',
            'requesterId': 'agent-1',
            'createdAt': DateTime.utc(2026),
          },
        ),
        throwsA(isA<ItsmRepositoryException>()),
      );
    });
  });
}
