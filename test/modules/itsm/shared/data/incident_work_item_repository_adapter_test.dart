import 'dart:async';

import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket_page.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_shared_data.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const principal = ItsmQueryPrincipal(
    sessionKey: 'manager|manager@example.com',
    userId: 'manager',
    email: 'manager@example.com',
    role: ItsmRole.manager,
  );

  group('IncidentItsmWorkItemRepository', () {
    test('adapts bounded incident pages and preserves the cursor', () async {
      final updatedAt = DateTime.utc(2026, 7, 30, 10);
      final source = _FakeIncidentSource(
        page: IncidentTicketPage(
          items: [_ticket(updatedAt: updatedAt)],
          hasMore: true,
          nextCursor: IncidentTicketPageCursor(
            updatedAt: updatedAt,
            documentId: 'incident-1',
          ),
        ),
      );
      final repository = IncidentItsmWorkItemRepository(source);

      final result = await repository.fetchPage(
        principal: principal,
        query: ItsmWorkItemQuery(
          scope: ItsmWorkItemScope.managerActive,
          types: const [ItsmWorkItemType.incident],
        ),
        page: PageRequest(limit: 20),
      );

      expect(source.lastPage?.limit, 20);
      expect(result.items, hasLength(1));
      expect(result.items.single.reference, 'INC-1');
      expect(result.items.single.type, ItsmWorkItemType.incident);
      expect(result.hasMore, isTrue);
      expect(result.nextCursor?['documentId'], 'incident-1');
      expect(
        result.nextCursor?['updatedAt'],
        updatedAt.toIso8601String(),
      );
    });

    test('maps requester and legacy incident values safely', () async {
      final source = _FakeIncidentSource(
        page: IncidentTicketPage(
          items: [
            _ticket(
              id: 'legacy-1',
              ticketNumber: '',
              title: '',
              createdByUserId: '',
              createdByEmail: '',
              status: 'cancelled',
              lifecycleState: 'active',
              includeCreatedAt: false,
              updatedAt: null,
            ),
          ],
          hasMore: false,
        ),
      );
      final repository = IncidentItsmWorkItemRepository(source);

      final result = await repository.fetchPage(
        principal: principal,
        query: ItsmWorkItemQuery(scope: ItsmWorkItemScope.managerActive),
        page: PageRequest(),
      );

      final summary = result.items.single;
      expect(summary.reference, 'legacy-1');
      expect(summary.title, 'Untitled incident');
      expect(summary.requesterId, 'legacy:legacy-1');
      expect(summary.lifecycleState, ItsmLifecycleState.cancelled);
      expect(summary.createdAt,
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
    });

    test('filters and limits the bounded first-page stream', () async {
      final source = _FakeIncidentSource(
        page: const IncidentTicketPage(items: [], hasMore: false),
        active: [
          _ticket(id: 'one', title: 'Printer offline', priority: 'P1'),
          _ticket(id: 'two', title: 'Wi-Fi offline', priority: 'P3'),
          _ticket(id: 'three', title: 'Printer jam', priority: 'P2'),
        ],
      );
      final repository = IncidentItsmWorkItemRepository(source);

      final result = await repository
          .watchFirstPage(
            principal: principal,
            query: ItsmWorkItemQuery(
              scope: ItsmWorkItemScope.managerActive,
              searchTerm: 'printer',
            ),
            limit: 1,
          )
          .first;

      expect(result, hasLength(1));
      expect(result.single.id, 'one');
    });

    test('does not expose raw incidents as executive reporting', () {
      final repository = IncidentItsmWorkItemRepository(
        _FakeIncidentSource(
          page: const IncidentTicketPage(items: [], hasMore: false),
        ),
      );

      expect(
        () => repository.watchFirstPage(
          principal: principal,
          query: ItsmWorkItemQuery(
            scope: ItsmWorkItemScope.executiveSnapshot,
          ),
          limit: 25,
        ),
        throwsA(isA<ItsmUnsupportedQueryException>()),
      );
    });

    test('rejects non-incident queries', () {
      final repository = IncidentItsmWorkItemRepository(
        _FakeIncidentSource(
          page: const IncidentTicketPage(items: [], hasMore: false),
        ),
      );

      expect(
        () => repository.watchFirstPage(
          principal: principal,
          query: ItsmWorkItemQuery(
            scope: ItsmWorkItemScope.managerActive,
            types: const [ItsmWorkItemType.changeRequest],
          ),
          limit: 25,
        ),
        throwsA(isA<ItsmUnsupportedQueryException>()),
      );
    });

    test('detail stream limits self-service roles to owned incidents',
        () async {
      final source = _FakeIncidentSource(
        page: const IncidentTicketPage(items: [], hasMore: false),
        active: [
          _ticket(id: 'owned'),
          _ticket(
            id: 'other',
            createdByUserId: 'other-user',
            createdByEmail: 'other@example.com',
          ),
        ],
      );
      final repository = IncidentItsmWorkItemRepository(source);
      const user = ItsmQueryPrincipal(
        sessionKey: 'user-1|user@example.com',
        userId: 'user-1',
        email: 'user@example.com',
        role: ItsmRole.user,
      );
      const admin = ItsmQueryPrincipal(
        sessionKey: 'user-1|user@example.com',
        userId: 'user-1',
        email: 'user@example.com',
        role: ItsmRole.admin,
      );

      expect(
        await repository
            .watchById(
              principal: user,
              type: ItsmWorkItemType.incident,
              id: 'owned',
            )
            .first,
        isNotNull,
      );
      expect(
        await repository
            .watchById(
              principal: user,
              type: ItsmWorkItemType.incident,
              id: 'other',
            )
            .first,
        isNull,
      );
      expect(
        await repository
            .watchById(
              principal: admin,
              type: ItsmWorkItemType.incident,
              id: 'other',
            )
            .first,
        isNull,
      );
    });

    test('manager detail stream excludes archived incidents', () async {
      final repository = IncidentItsmWorkItemRepository(
        _FakeIncidentSource(
          page: const IncidentTicketPage(items: [], hasMore: false),
          active: [_ticket(id: 'archived', lifecycleState: 'archived')],
        ),
      );

      expect(
        await repository
            .watchById(
              principal: principal,
              type: ItsmWorkItemType.incident,
              id: 'archived',
            )
            .first,
        isNull,
      );
    });
  });
}

class _FakeIncidentSource implements IncidentWorkItemReadSource {
  _FakeIncidentSource({
    required this.page,
    this.active = const [],
  });

  final IncidentTicketPage page;
  final List<IncidentTicket> active;
  IncidentTicketPageRequest? lastPage;

  @override
  Future<IncidentTicketPage> fetchAssignedToMe(
    String userId,
    IncidentTicketPageRequest page,
  ) async {
    lastPage = page;
    return this.page;
  }

  @override
  Future<IncidentTicketPage> fetchManagerActive(
    IncidentTicketPageRequest page,
  ) async {
    lastPage = page;
    return this.page;
  }

  @override
  Future<IncidentTicketPage> fetchManagerClosed(
    IncidentTicketPageRequest page,
  ) async {
    lastPage = page;
    return this.page;
  }

  @override
  Future<IncidentTicketPage> fetchMyActive(
    String email,
    IncidentTicketPageRequest page,
  ) async {
    lastPage = page;
    return this.page;
  }

  @override
  Future<IncidentTicketPage> fetchMyHistory(
    String email,
    IncidentTicketPageRequest page,
  ) async {
    lastPage = page;
    return this.page;
  }

  @override
  Stream<List<IncidentTicket>> watchAssignedToMe(String userId) {
    return Stream.value(active);
  }

  @override
  Stream<IncidentTicket?> watchById(String id) {
    return Stream.value(active.where((ticket) => ticket.id == id).firstOrNull);
  }

  @override
  Stream<List<IncidentTicket>> watchManagerActive() {
    return Stream.value(active);
  }

  @override
  Stream<List<IncidentTicket>> watchManagerClosed() {
    return Stream.value(active);
  }

  @override
  Stream<List<IncidentTicket>> watchMyActive(String email) {
    return Stream.value(active);
  }

  @override
  Stream<List<IncidentTicket>> watchMyHistory(String email) {
    return Stream.value(active);
  }
}

IncidentTicket _ticket({
  String id = 'incident-1',
  String ticketNumber = 'INC-1',
  String title = 'Network unavailable',
  String createdByUserId = 'user-1',
  String createdByEmail = 'user@example.com',
  String? affectedUserId,
  String? affectedUserEmail,
  String status = 'open',
  String lifecycleState = 'active',
  String priority = 'P1',
  bool includeCreatedAt = true,
  DateTime? updatedAt,
}) {
  final createdAt = DateTime.utc(2026, 7, 29, 9);
  return IncidentTicket(
    id: id,
    ticketNumber: ticketNumber,
    title: title,
    description: 'Description',
    status: status,
    lifecycleState: lifecycleState,
    createdByUserId: createdByUserId,
    createdByName: 'User One',
    createdByEmail: createdByEmail,
    createdByDepartmentId: 'department-1',
    createdByDepartmentName: 'IT',
    createdByServiceId: 'service-1',
    createdByServiceName: 'Support',
    affectedUserId: affectedUserId ?? createdByUserId,
    affectedUserName: 'User One',
    affectedUserEmail: affectedUserEmail ?? createdByEmail,
    affectedServiceId: 'service-1',
    affectedServiceName: 'Internet',
    location: '',
    deviceType: '',
    assetId: '',
    userImpactDescription: '',
    isBlocking: false,
    categoryId: '',
    categoryName: '',
    subcategoryId: '',
    subcategoryName: '',
    impact: 'high',
    urgency: 'high',
    priority: priority,
    assignedToUserId: '',
    assignedToName: '',
    assignedToEmail: '',
    resolutionSummary: '',
    resolutionCode: '',
    closedByUserId: '',
    closedByName: '',
    closedAt: null,
    archivedAt: null,
    archiveEligibleAt: null,
    createdAt: includeCreatedAt ? createdAt : null,
    updatedAt: updatedAt,
    lastCommentAt: null,
    lastStatusChangedAt: null,
    attachmentCount: 0,
    commentCount: 0,
    isDeleted: false,
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final values = iterator;
    return values.moveNext() ? values.current : null;
  }
}
