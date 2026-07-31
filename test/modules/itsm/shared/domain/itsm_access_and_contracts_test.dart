import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItsmPermissionPolicy', () {
    test('uses only the USER, MANAGER, and ADMIN roles', () {
      expect(ItsmRole.values, hasLength(3));
      expect(ItsmRole.tryParse('user'), ItsmRole.user);
      expect(ItsmRole.tryParse('MANAGER'), ItsmRole.manager);
      expect(ItsmRole.tryParse('admin'), ItsmRole.admin);
      expect(ItsmRole.tryParse('NONE'), isNull);
    });

    test('keeps ADMIN self-service and reporting read-only', () {
      const policy = ItsmPermissionPolicy(ItsmRole.admin);

      expect(policy.canUseSelfService, isTrue);
      expect(policy.canCreateSelfServiceRecord, isTrue);
      expect(policy.canReadExecutiveReporting, isTrue);
      expect(policy.canOperate, isFalse);
      expect(policy.canManageConfiguration, isFalse);
      expect(policy.isExecutiveReadOnly, isTrue);
      expect(
        policy.canReadWorkItem(
          currentUserId: 'admin-1',
          requesterUserId: 'admin-1',
        ),
        isTrue,
      );
      expect(
        policy.canReadWorkItem(
          currentUserId: 'admin-1',
          requesterUserId: 'user-2',
        ),
        isFalse,
      );
    });

    test('gives MANAGER operational access and USER own-record access', () {
      const manager = ItsmPermissionPolicy(ItsmRole.manager);
      const user = ItsmPermissionPolicy(ItsmRole.user);

      expect(manager.canOperate, isTrue);
      expect(
        manager.canReadWorkItem(
          currentUserId: 'manager-1',
          requesterUserId: 'user-2',
          confidentiality: ItsmConfidentiality.restricted,
        ),
        isTrue,
      );
      expect(
        user.canReadWorkItem(
          currentUserId: 'user-1',
          requesterUserId: 'user-1',
          confidentiality: ItsmConfidentiality.restricted,
        ),
        isTrue,
      );
      expect(
        user.canReadWorkItem(
          currentUserId: 'user-1',
          requesterUserId: 'user-2',
        ),
        isFalse,
      );
    });
  });

  group('ItsmWorkItemSummary', () {
    test('provides the common read contract and immutable link collections',
        () {
      final assets = <String>['asset-1'];
      final item = _workItem(linkedAssetIds: assets);
      assets.add('asset-2');

      expect(item.linkedAssetIds, ['asset-1']);
      expect(
        () => item.linkedAssetIds.add('asset-3'),
        throwsUnsupportedError,
      );
      expect(item.isOwnedBy('user-1'), isTrue);
      expect(item.isClosed, isFalse);
      expect(item.toPrimitiveMap()['type'], 'service_request');
      expect(
        item.toPrimitiveMap()['createdAt'],
        '2026-07-31T08:00:00.000Z',
      );
    });

    test('rejects invalid workflow versions and required identifiers', () {
      expect(
        () => _workItem(workflowVersion: 0),
        throwsRangeError,
      );
      expect(
        () => _workItem(id: ''),
        throwsArgumentError,
      );
    });
  });

  group('Pagination', () {
    test('enforces bounded page sizes and cursor presence', () {
      expect(PageRequest().limit, PageRequest.defaultLimit);
      expect(() => PageRequest(limit: 0), throwsRangeError);
      expect(
        () => PageRequest(limit: PageRequest.maximumLimit + 1),
        throwsRangeError,
      );
      expect(
        () => PageResult<String>(items: const [], hasMore: true),
        throwsArgumentError,
      );
    });

    test('keeps cursor and results immutable and maps result values', () {
      final values = <String, Object?>{
        'createdAt': '2026-07-31T08:00:00Z',
        'id': 'item-1',
      };
      final cursor = PageCursor(values);
      final reorderedCursor = PageCursor({
        'id': 'item-1',
        'createdAt': '2026-07-31T08:00:00Z',
      });
      values['id'] = 'changed';
      final page = PageResult<int>(
        items: const [1, 2],
        hasMore: true,
        nextCursor: cursor,
      );

      expect(cursor['id'], 'item-1');
      expect(cursor, reorderedCursor);
      expect(cursor.hashCode, reorderedCursor.hashCode);
      expect(() => cursor.values['id'] = 'changed', throwsUnsupportedError);
      expect(page.map((value) => 'item-$value').items, ['item-1', 'item-2']);
      expect(() => page.items.add(3), throwsUnsupportedError);
    });
  });
}

ItsmWorkItemSummary _workItem({
  String id = 'request-1',
  int? workflowVersion = 1,
  Iterable<String> linkedAssetIds = const [],
}) {
  return ItsmWorkItemSummary(
    id: id,
    reference: 'REQ-0001',
    type: ItsmWorkItemType.serviceRequest,
    title: 'Request a computer',
    requesterId: 'user-1',
    status: 'submitted',
    lifecycleState: ItsmLifecycleState.active,
    workflowDefinitionId: 'computer-request',
    workflowVersion: workflowVersion,
    createdAt: DateTime.utc(2026, 7, 31, 8),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 7, 31, 8),
    updatedBy: 'user-1',
    linkedAssetIds: linkedAssetIds,
  );
}
