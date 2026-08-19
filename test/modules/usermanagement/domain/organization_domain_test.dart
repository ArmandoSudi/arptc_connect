import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_assignment.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assignment query identity includes organization and subject', () {
    const first = OrganizationAssignmentQuery.agent(
      organizationId: 'org-a',
      agentId: 'agent-a',
    );
    const same = OrganizationAssignmentQuery.agent(
      organizationId: 'org-a',
      agentId: 'agent-a',
    );
    const otherOrganization = OrganizationAssignmentQuery.agent(
      organizationId: 'org-b',
      agentId: 'agent-a',
    );
    const unit = OrganizationAssignmentQuery.unit(
      organizationId: 'org-a',
      unitId: 'agent-a',
    );

    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first, isNot(otherOrganization));
    expect(first, isNot(unit));
    expect(first.isValid, isTrue);
  });

  group('OrganizationHierarchyPolicy', () {
    const policy = OrganizationHierarchyPolicy();

    test('accepts the default Department, Service, Bureau hierarchy', () {
      expect(
        policy.acceptsParent(
          childType: OrganizationUnitType.department,
          parentType: null,
        ),
        isTrue,
      );
      expect(
        policy.acceptsParent(
          childType: OrganizationUnitType.service,
          parentType: OrganizationUnitType.department,
        ),
        isTrue,
      );
      expect(
        policy.acceptsParent(
          childType: OrganizationUnitType.bureau,
          parentType: OrganizationUnitType.service,
        ),
        isTrue,
      );
    });

    test('rejects invalid and skipped hierarchy levels', () {
      expect(
        policy.acceptsParent(
          childType: OrganizationUnitType.bureau,
          parentType: OrganizationUnitType.department,
        ),
        isFalse,
      );
      expect(
        policy.acceptsParent(
          childType: OrganizationUnitType.service,
          parentType: null,
        ),
        isFalse,
      );
      expect(
        policy.allowedChildTypes(OrganizationUnitType.bureau),
        isEmpty,
      );
    });

    test('declares the only next level for each default hierarchy node', () {
      expect(
        policy.allowedChildTypes(null),
        [OrganizationUnitType.department],
      );
      expect(
        policy.allowedChildTypes(OrganizationUnitType.department),
        [OrganizationUnitType.service],
      );
      expect(
        policy.allowedChildTypes(OrganizationUnitType.service),
        [OrganizationUnitType.bureau],
      );
      expect(
        policy.allowedChildTypes(OrganizationUnitType.bureau),
        isEmpty,
      );
    });

    test('reports required parent types used by hierarchy dialogs', () {
      expect(
        policy.requiredParentType(OrganizationUnitType.department),
        isNull,
      );
      expect(
        policy.requiredParentType(OrganizationUnitType.service),
        OrganizationUnitType.department,
      );
      expect(
        policy.requiredParentType(OrganizationUnitType.bureau),
        OrganizationUnitType.service,
      );
    });

    test('custom units require a parent and may form custom chains', () {
      expect(
        policy.acceptsParent(
          childType: OrganizationUnitType.custom,
          parentType: null,
        ),
        isFalse,
      );
      expect(
        policy.acceptsParent(
          childType: OrganizationUnitType.custom,
          parentType: OrganizationUnitType.custom,
        ),
        isTrue,
      );
      expect(
        policy.allowedChildTypes(OrganizationUnitType.custom),
        [OrganizationUnitType.custom],
      );
    });
  });

  test('Organization reads status and schema fields', () {
    final organization = Organization.fromMap(
      {
        'code': 'ARPTC',
        'name': 'ARPTC',
        'description': 'Regulatory authority',
        'status': 'inactive',
        'schemaVersion': 2,
      },
      id: 'org-arptc',
    );

    expect(organization.id, 'org-arptc');
    expect(organization.status, OrganizationStatus.inactive);
    expect(organization.nameLower, 'arptc');
    expect(organization.schemaVersion, 2);
  });

  test('OrganizationUnit reads authoritative path projections', () {
    final unit = OrganizationUnit.fromMap(
      {
        'organizationId': 'org-arptc',
        'type': 'BUREAU',
        'code': 'B-SUP',
        'name': 'Support Desk',
        'parentUnitId': 'service-it',
        'parentUnitType': 'SERVICE',
        'ancestorUnitIds': ['department-it', 'service-it'],
        'pathUnitIds': ['department-it', 'service-it', 'bureau-support'],
        'pathNames': ['IT', 'Operations', 'Support Desk'],
        'scopeKeys': [
          'org:org-arptc',
          'unit:department-it',
          'unit:service-it',
          'unit:bureau-support',
        ],
        'depth': 2,
        'status': 'ACTIVE',
      },
      id: 'bureau-support',
    );

    expect(unit.type, OrganizationUnitType.bureau);
    expect(unit.parentUnitType, OrganizationUnitType.service);
    expect(unit.breadcrumb, 'IT / Operations / Support Desk');
    expect(unit.depth, 2);
    expect(unit.scopeKeys, contains('unit:department-it'));
    expect(() => unit.pathUnitIds.add('forged'), throwsUnsupportedError);
  });

  test('OrganizationUnit reads permanent and acting leadership separately', () {
    final unit = OrganizationUnit.fromMap(
      {
        'organizationId': 'org-arptc',
        'type': 'SERVICE',
        'code': 'S-OPS',
        'name': 'Operations',
        'headUserId': 'uid-permanent',
        'headAssignmentId': 'head-permanent',
        'actingHeadUserId': 'uid-acting',
        'actingHeadAssignmentId': 'head-acting',
        'actingHeadEndsAt': '2026-08-31T00:00:00.000Z',
        'status': 'ACTIVE',
      },
      id: 'service-operations',
    );

    expect(unit.headUserId, 'uid-permanent');
    expect(unit.headAssignmentId, 'head-permanent');
    expect(unit.actingHeadUserId, 'uid-acting');
    expect(unit.actingHeadAssignmentId, 'head-acting');
    expect(unit.actingHeadEndsAt, DateTime.utc(2026, 8, 31));
  });

  test('OrganizationAssignment keeps historical snapshots', () {
    final assignment = OrganizationAssignment.fromMap(
      {
        'organizationId': 'org-arptc',
        'agentId': 'uid-1',
        'unitId': 'bureau-support',
        'unitType': 'BUREAU',
        'unitName': 'Support Desk',
        'ancestorUnitIds': ['department-it', 'service-it'],
        'pathUnitIds': ['department-it', 'service-it', 'bureau-support'],
        'pathNames': ['IT', 'Operations', 'Support Desk'],
        'scopeKeys': ['org:org-arptc', 'unit:bureau-support'],
        'assignmentType': 'HEAD',
        'isPrimary': false,
        'isActing': true,
        'status': 'ACTIVE',
        'startsAt': '2026-08-01T00:00:00.000Z',
        'reason': 'Acting appointment',
      },
      id: 'assignment-1',
    );

    expect(assignment.assignmentType, OrganizationAssignmentType.head);
    expect(assignment.isActing, isTrue);
    expect(assignment.isCurrent, isTrue);
    expect(assignment.pathNames.last, 'Support Desk');
  });

  test('ended assignments remain historical and are not current', () {
    final assignment = OrganizationAssignment.fromMap(
      {
        'organizationId': 'org-arptc',
        'agentId': 'uid-1',
        'unitId': 'bureau-support',
        'unitType': 'BUREAU',
        'unitName': 'Support Desk',
        'pathNames': ['IT', 'Operations', 'Support Desk'],
        'assignmentType': 'MEMBER',
        'isPrimary': true,
        'status': 'ENDED',
        'startsAt': '2025-01-01T00:00:00.000Z',
        'endsAt': '2026-07-31T00:00:00.000Z',
        'endedAt': '2026-07-31T00:00:00.000Z',
        'endedBy': 'manager-1',
        'reason': 'Transfer to Infrastructure',
      },
      id: 'assignment-old',
    );

    expect(assignment.isCurrent, isFalse);
    expect(assignment.isPrimary, isTrue);
    expect(assignment.endsAt, DateTime.utc(2026, 7, 31));
    expect(assignment.endedBy, 'manager-1');
    expect(assignment.pathNames, ['IT', 'Operations', 'Support Desk']);
    expect(() => assignment.pathNames.add('Changed'), throwsUnsupportedError);
  });

  test('OrganizationPageRequest rejects unbounded page sizes', () {
    expect(
      () => OrganizationPageRequest(
        limit: OrganizationPageRequest.maximumLimit + 1,
      ),
      throwsAssertionError,
    );
    expect(
      const OrganizationPageRequest(search: '  Support ').normalizedSearch,
      'support',
    );
  });

  test('OrganizationPageRequest accepts the documented maximum page size', () {
    const request = OrganizationPageRequest(
      limit: OrganizationPageRequest.maximumLimit,
      afterNameLower: 'support',
      afterId: 'unit-50',
    );

    expect(request.limit, 100);
    expect(request.afterNameLower, 'support');
    expect(request.afterId, 'unit-50');
    expect(() => OrganizationPageRequest(limit: 0), throwsAssertionError);
  });

  test('OrganizationPage exposes stable cursor availability', () {
    const cursor = OrganizationPageCursor(
      nameLower: 'support',
      id: 'unit-50',
    );
    const populated = OrganizationPage<String>(
      items: ['unit-1'],
      nextCursor: cursor,
    );
    const terminal = OrganizationPage<String>(
      items: ['unit-2'],
      nextCursor: null,
    );

    expect(populated.hasMore, isTrue);
    expect(populated.nextCursor?.id, 'unit-50');
    expect(terminal.hasMore, isFalse);
  });
}
