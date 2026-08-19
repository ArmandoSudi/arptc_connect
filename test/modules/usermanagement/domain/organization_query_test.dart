import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('organization unit identity is stable and requires both boundaries', () {
    const identity = OrganizationUnitIdentity(
      organizationId: 'org-arptc',
      unitId: 'service-infrastructure',
    );

    expect(identity.isValid, isTrue);
    expect(
      identity,
      const OrganizationUnitIdentity(
        organizationId: 'org-arptc',
        unitId: 'service-infrastructure',
      ),
    );
    expect(
      const OrganizationUnitIdentity(
        organizationId: 'org-arptc',
        unitId: '',
      ).isValid,
      isFalse,
    );
  });

  group('organization list filters', () {
    test('map every status to the expected Firestore values', () {
      expect(
        OrganizationListStatusFilter.current.firestoreValues,
        ['ACTIVE', 'INACTIVE'],
      );
      expect(OrganizationListStatusFilter.active.firestoreValues, ['ACTIVE']);
      expect(
        OrganizationListStatusFilter.inactive.firestoreValues,
        ['INACTIVE'],
      );
      expect(
        OrganizationListStatusFilter.archived.firestoreValues,
        ['ARCHIVED'],
      );
      expect(OrganizationListStatusFilter.all.firestoreValues, isNull);
    });

    test('normalize search before equality and hashing', () {
      const first = OrganizationListQuery(search: '  ARPTC  ');
      const same = OrganizationListQuery(search: 'arptc');
      const otherStatus = OrganizationListQuery(
        search: 'arptc',
        status: OrganizationListStatusFilter.archived,
      );
      const otherLimit = OrganizationListQuery(search: 'arptc', limit: 41);

      expect(first.normalizedSearch, 'arptc');
      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(otherStatus));
      expect(first, isNot(otherLimit));
    });

    test('reject list limits outside the bounded range', () {
      expect(() => OrganizationListQuery(limit: 0), throwsAssertionError);
      expect(() => OrganizationListQuery(limit: 101), throwsAssertionError);
      expect(
        const OrganizationListQuery(limit: 100).limit,
        OrganizationPageRequest.maximumLimit,
      );
    });
  });

  group('organization unit queries', () {
    test('normalize search and unit type for provider-family identity', () {
      const first = OrganizationUnitListQuery(
        organizationId: 'org-a',
        search: '  Support ',
        type: ' service ',
      );
      const same = OrganizationUnitListQuery(
        organizationId: 'org-a',
        search: 'support',
        type: 'SERVICE',
      );
      const noType = OrganizationUnitListQuery(
        organizationId: 'org-a',
        search: 'support',
        type: '   ',
      );

      expect(first.normalizedSearch, 'support');
      expect(first.normalizedType, 'SERVICE');
      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(noType.normalizedType, isNull);
      expect(first, isNot(noType));
    });

    test('include organization, status, and limit in equality', () {
      const baseline = OrganizationUnitListQuery(organizationId: 'org-a');

      expect(
        baseline,
        isNot(const OrganizationUnitListQuery(organizationId: 'org-b')),
      );
      expect(
        baseline,
        isNot(const OrganizationUnitListQuery(
          organizationId: 'org-a',
          status: OrganizationListStatusFilter.all,
        )),
      );
      expect(
        baseline,
        isNot(const OrganizationUnitListQuery(
          organizationId: 'org-a',
          limit: 25,
        )),
      );
    });

    test('enforce the common maximum page size', () {
      expect(
        () => OrganizationUnitListQuery(
          organizationId: 'org-a',
          limit: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => OrganizationUnitListQuery(
          organizationId: 'org-a',
          limit: 101,
        ),
        throwsAssertionError,
      );
    });
  });

  group('agent directory queries', () {
    test('normalize search and retain scope in query identity', () {
      const first = AgentDirectoryListQuery(
        organizationId: 'org-a',
        search: '  Alice ',
        scopeUnitId: 'unit-a',
      );
      const same = AgentDirectoryListQuery(
        organizationId: 'org-a',
        search: 'alice',
        scopeUnitId: 'unit-a',
      );

      expect(first.normalizedSearch, 'alice');
      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(
        first,
        isNot(const AgentDirectoryListQuery(
          organizationId: 'org-a',
          search: 'alice',
          scopeUnitId: 'unit-b',
        )),
      );
      expect(
        first,
        isNot(const AgentDirectoryListQuery(
          organizationId: 'org-a',
          search: 'alice',
          scopeUnitId: 'unit-a',
          status: AgentDirectoryStatusFilter.inactive,
        )),
      );
    });

    test('reject unbounded directory queries', () {
      expect(
        () => AgentDirectoryListQuery(
          organizationId: 'org-a',
          limit: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => AgentDirectoryListQuery(
          organizationId: 'org-a',
          limit: 101,
        ),
        throwsAssertionError,
      );
    });
  });

  group('assignment and audit query identity', () {
    test('distinguish agent and unit assignment subjects', () {
      const agent = OrganizationAssignmentQuery.agent(
        organizationId: 'org-a',
        agentId: 'subject-a',
      );
      const sameAgent = OrganizationAssignmentQuery.agent(
        organizationId: 'org-a',
        agentId: 'subject-a',
      );
      const unit = OrganizationAssignmentQuery.unit(
        organizationId: 'org-a',
        unitId: 'subject-a',
      );

      expect(agent, sameAgent);
      expect(agent.hashCode, sameAgent.hashCode);
      expect(agent, isNot(unit));
      expect(agent.agentId, 'subject-a');
      expect(agent.unitId, isEmpty);
      expect(unit.agentId, isEmpty);
      expect(unit.unitId, 'subject-a');
      expect(agent.isValid, isTrue);
      expect(
        const OrganizationAssignmentQuery.agent(
          organizationId: ' ',
          agentId: 'subject-a',
        ).isValid,
        isFalse,
      );
      expect(
        const OrganizationAssignmentQuery.unit(
          organizationId: 'org-a',
          unitId: ' ',
        ).isValid,
        isFalse,
      );
    });

    test('enforce assignment and audit page limits', () {
      expect(
        () => OrganizationAssignmentQuery.agent(
          organizationId: 'org-a',
          agentId: 'agent-a',
          limit: 101,
        ),
        throwsAssertionError,
      );
      expect(
        () => OrganizationAuditQuery(
          organizationId: 'org-a',
          limit: 0,
        ),
        throwsAssertionError,
      );
      expect(
        const OrganizationAuditQuery(
          organizationId: 'org-a',
          limit: 100,
        ).isValid,
        isTrue,
      );
    });

    test('include organization and limit in audit query identity', () {
      const first = OrganizationAuditQuery(organizationId: 'org-a');
      const same = OrganizationAuditQuery(organizationId: 'org-a');

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(
          first, isNot(const OrganizationAuditQuery(organizationId: 'org-b')));
      expect(
        first,
        isNot(const OrganizationAuditQuery(
          organizationId: 'org-a',
          limit: 20,
        )),
      );
      expect(
        const OrganizationAuditQuery(organizationId: '  ').isValid,
        isFalse,
      );
    });
  });

  group('page and timeline cursors', () {
    test('preserve stable name and document-ID page cursors', () {
      const cursor = OrganizationPageCursor(
        nameLower: 'support',
        id: 'unit-042',
      );
      const page = OrganizationPage<String>(
        items: ['unit-041', 'unit-042'],
        nextCursor: cursor,
      );

      expect(page.hasMore, isTrue);
      expect(page.nextCursor?.nameLower, 'support');
      expect(page.nextCursor?.id, 'unit-042');
      expect(
        const OrganizationPage<String>(items: [], nextCursor: null).hasMore,
        isFalse,
      );
    });

    test('require both timeline cursor components', () {
      final timestamp = DateTime.utc(2026, 8, 11, 10);

      expect(
        OrganizationTimelinePageRequest(
          afterTimestamp: timestamp,
          afterId: 'audit-42',
        ).hasCursor,
        isTrue,
      );
      expect(
        OrganizationTimelinePageRequest(afterTimestamp: timestamp).hasCursor,
        isFalse,
      );
      expect(
        const OrganizationTimelinePageRequest(afterId: 'audit-42').hasCursor,
        isFalse,
      );
      expect(
        OrganizationTimelinePageRequest(
          afterTimestamp: timestamp,
          afterId: '   ',
        ).hasCursor,
        isFalse,
      );
      expect(
        () => OrganizationTimelinePageRequest(limit: 101),
        throwsAssertionError,
      );
    });

    test('expose timeline continuation state from its cursor', () {
      final cursor = OrganizationTimelineCursor(
        timestamp: DateTime.utc(2026, 8, 11),
        id: 'audit-42',
      );
      final page = OrganizationTimelinePage<String>(
        items: const ['audit-42'],
        nextCursor: cursor,
      );

      expect(page.hasMore, isTrue);
      expect(page.nextCursor?.timestamp, DateTime.utc(2026, 8, 11));
      expect(page.nextCursor?.id, 'audit-42');
      expect(
        const OrganizationTimelinePage<String>(
          items: [],
          nextCursor: null,
        ).hasMore,
        isFalse,
      );
    });
  });
}
