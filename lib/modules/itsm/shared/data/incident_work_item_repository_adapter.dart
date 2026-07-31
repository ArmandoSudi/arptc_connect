import 'package:arptc_connect/modules/incident_management/data/incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket_page.dart';

import '../domain/itsm_shared_domain.dart';
import 'itsm_work_item_repository.dart';

abstract interface class IncidentWorkItemReadSource {
  Future<IncidentTicketPage> fetchMyActive(
    String email,
    IncidentTicketPageRequest page,
  );

  Future<IncidentTicketPage> fetchMyHistory(
    String email,
    IncidentTicketPageRequest page,
  );

  Future<IncidentTicketPage> fetchManagerActive(IncidentTicketPageRequest page);

  Future<IncidentTicketPage> fetchManagerClosed(IncidentTicketPageRequest page);

  Future<IncidentTicketPage> fetchAssignedToMe(
    String userId,
    IncidentTicketPageRequest page,
  );

  Stream<List<IncidentTicket>> watchMyActive(String email);

  Stream<List<IncidentTicket>> watchMyHistory(String email);

  Stream<List<IncidentTicket>> watchManagerActive();

  Stream<List<IncidentTicket>> watchManagerClosed();

  Stream<List<IncidentTicket>> watchAssignedToMe(String userId);

  Stream<IncidentTicket?> watchById(String id);
}

class ExistingIncidentWorkItemReadSource implements IncidentWorkItemReadSource {
  const ExistingIncidentWorkItemReadSource(this._repository);

  final IncidentRepository _repository;

  @override
  Future<IncidentTicketPage> fetchMyActive(
    String email,
    IncidentTicketPageRequest page,
  ) {
    return _repository.fetchMyActiveTicketsPage(email, page);
  }

  @override
  Future<IncidentTicketPage> fetchMyHistory(
    String email,
    IncidentTicketPageRequest page,
  ) {
    return _repository.fetchMyClosedAndArchivedTicketsPage(email, page);
  }

  @override
  Future<IncidentTicketPage> fetchManagerActive(
    IncidentTicketPageRequest page,
  ) {
    return _repository.fetchManagerActiveTicketsPage(page);
  }

  @override
  Future<IncidentTicketPage> fetchManagerClosed(
    IncidentTicketPageRequest page,
  ) {
    return _repository.fetchManagerClosedTicketsPage(page);
  }

  @override
  Future<IncidentTicketPage> fetchAssignedToMe(
    String userId,
    IncidentTicketPageRequest page,
  ) {
    return _repository.fetchAssignedToMeTicketsPage(userId, page);
  }

  @override
  Stream<List<IncidentTicket>> watchMyActive(String email) {
    return _repository.watchMyActiveTickets(email);
  }

  @override
  Stream<List<IncidentTicket>> watchMyHistory(String email) {
    return _repository.watchMyClosedAndArchivedTickets(email);
  }

  @override
  Stream<List<IncidentTicket>> watchManagerActive() {
    return _repository.watchAllActiveTicketsForManagers();
  }

  @override
  Stream<List<IncidentTicket>> watchManagerClosed() {
    return _repository.watchAllClosedTicketsForManagers();
  }

  @override
  Stream<List<IncidentTicket>> watchAssignedToMe(String userId) {
    return _repository.watchAssignedToMeTickets(userId);
  }

  @override
  Stream<IncidentTicket?> watchById(String id) {
    return _repository.watchTicketById(id);
  }
}

class IncidentItsmWorkItemRepository implements ItsmWorkItemRepository {
  const IncidentItsmWorkItemRepository(this._source);

  final IncidentWorkItemReadSource _source;

  @override
  Future<PageResult<ItsmWorkItemSummary>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemQuery query,
    required PageRequest page,
  }) async {
    _ensureIncidentQuery(query);
    final incidentPage = _toIncidentPageRequest(page);
    final result = switch (query.scope) {
      ItsmWorkItemScope.myActive =>
        _source.fetchMyActive(_requireEmail(principal), incidentPage),
      ItsmWorkItemScope.myHistory =>
        _source.fetchMyHistory(_requireEmail(principal), incidentPage),
      ItsmWorkItemScope.managerActive =>
        _source.fetchManagerActive(incidentPage),
      ItsmWorkItemScope.managerClosed =>
        _source.fetchManagerClosed(incidentPage),
      ItsmWorkItemScope.assignedToMe =>
        _source.fetchAssignedToMe(_requireUserId(principal), incidentPage),
      ItsmWorkItemScope.executiveSnapshot =>
        throw const ItsmUnsupportedQueryException(
          'Raw incidents are not an executive reporting data source.',
        ),
    };

    return _toPageResult(await result, query);
  }

  @override
  Stream<List<ItsmWorkItemSummary>> watchFirstPage({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemQuery query,
    required int limit,
  }) {
    if (limit < 1 || limit > PageRequest.maximumLimit) {
      throw RangeError.range(limit, 1, PageRequest.maximumLimit, 'limit');
    }
    _ensureIncidentQuery(query);
    final stream = switch (query.scope) {
      ItsmWorkItemScope.myActive =>
        _source.watchMyActive(_requireEmail(principal)),
      ItsmWorkItemScope.myHistory =>
        _source.watchMyHistory(_requireEmail(principal)),
      ItsmWorkItemScope.managerActive => _source.watchManagerActive(),
      ItsmWorkItemScope.managerClosed => _source.watchManagerClosed(),
      ItsmWorkItemScope.assignedToMe =>
        _source.watchAssignedToMe(_requireUserId(principal)),
      ItsmWorkItemScope.executiveSnapshot =>
        throw const ItsmUnsupportedQueryException(
          'Raw incidents are not an executive reporting data source.',
        ),
    };

    return stream.map(
      (tickets) => tickets
          .map(_toSummary)
          .where(query.matches)
          .take(limit)
          .toList(growable: false),
    );
  }

  @override
  Stream<ItsmWorkItemSummary?> watchById({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemType type,
    required String id,
  }) {
    if (type != ItsmWorkItemType.incident) {
      throw ItsmUnsupportedQueryException(
        'The incident adapter cannot read ${type.value}.',
      );
    }
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'A work-item ID is required.');
    }
    return _source.watchById(id.trim()).map(
          (ticket) => ticket == null || !_canReadTicket(principal, ticket)
              ? null
              : _toSummary(ticket),
        );
  }

  void _ensureIncidentQuery(ItsmWorkItemQuery query) {
    if (!query.includesType(ItsmWorkItemType.incident) ||
        query.types.any((type) => type != ItsmWorkItemType.incident)) {
      throw const ItsmUnsupportedQueryException(
        'The legacy incident adapter accepts incident-only queries.',
      );
    }
  }
}

bool _canReadTicket(
  ItsmQueryPrincipal principal,
  IncidentTicket ticket,
) {
  if (principal.role == ItsmRole.manager) {
    return ticket.lifecycleState == 'active' ||
        ticket.lifecycleState == 'closed';
  }

  final userId = principal.userId.trim();
  final email = principal.email.trim().toLowerCase();
  return (userId.isNotEmpty &&
          (ticket.createdByUserId.trim() == userId ||
              ticket.affectedUserId.trim() == userId)) ||
      (email.isNotEmpty &&
          (ticket.createdByEmail.trim().toLowerCase() == email ||
              ticket.affectedUserEmail.trim().toLowerCase() == email));
}

IncidentTicketPageRequest _toIncidentPageRequest(PageRequest page) {
  final cursor = page.cursor;
  IncidentTicketPageCursor? incidentCursor;
  if (cursor != null) {
    final updatedAt = _dateFromCursor(cursor['updatedAt']);
    final documentId = cursor['documentId']?.toString().trim() ?? '';
    if (updatedAt == null || documentId.isEmpty) {
      throw const ItsmUnsupportedQueryException(
        'Incident cursors require updatedAt and documentId values.',
      );
    }
    incidentCursor = IncidentTicketPageCursor(
      updatedAt: updatedAt,
      documentId: documentId,
    );
  }
  return IncidentTicketPageRequest(limit: page.limit, cursor: incidentCursor);
}

PageResult<ItsmWorkItemSummary> _toPageResult(
  IncidentTicketPage page,
  ItsmWorkItemQuery query,
) {
  final items = page.items.map(_toSummary).where(query.matches).toList();
  final incidentCursor = page.nextCursor;
  final nextCursor = incidentCursor == null
      ? null
      : PageCursor({
          'updatedAt': incidentCursor.updatedAt.toUtc().toIso8601String(),
          'documentId': incidentCursor.documentId,
        });
  return PageResult(
    items: items,
    hasMore: page.hasMore,
    nextCursor: nextCursor,
  );
}

ItsmWorkItemSummary _toSummary(IncidentTicket ticket) {
  final createdAt = ticket.createdAt ??
      ticket.updatedAt ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final updatedAt = ticket.updatedAt ?? createdAt;
  final requesterId = _firstNonEmpty([
    ticket.createdByUserId,
    ticket.createdByEmail,
    'legacy:${ticket.id}',
  ]);
  final createdBy = _firstNonEmpty([ticket.createdByUserId, requesterId]);
  final updatedBy = _firstNonEmpty([
    ticket.closedByUserId,
    ticket.assignedToUserId,
    createdBy,
  ]);

  return ItsmWorkItemSummary(
    id: ticket.id,
    reference: _firstNonEmpty([ticket.ticketNumber, ticket.id]),
    type: ItsmWorkItemType.incident,
    title: _firstNonEmpty([ticket.title, 'Untitled incident']),
    description: ticket.description,
    requesterId: requesterId,
    affectedUserId: _nullable(ticket.affectedUserId),
    departmentId: _nullable(ticket.createdByDepartmentId),
    serviceId: _nullable(ticket.affectedServiceId),
    assignedUserId: _nullable(ticket.assignedToUserId),
    priority: ItsmPriority.fromValue(ticket.priority),
    impact: _impact(ticket.impact),
    urgency: _urgency(ticket.urgency),
    status: ticket.status,
    lifecycleState: ticket.status == 'cancelled'
        ? ItsmLifecycleState.cancelled
        : ItsmLifecycleState.tryParse(ticket.lifecycleState) ??
            ItsmLifecycleState.active,
    createdAt: createdAt,
    createdBy: createdBy,
    updatedAt: updatedAt,
    updatedBy: updatedBy,
    closedAt: ticket.closedAt,
    linkedAssetIds:
        ticket.assetId.trim().isEmpty ? const [] : [ticket.assetId.trim()],
  );
}

ItsmImpact? _impact(String value) {
  return switch (value.trim().toLowerCase()) {
    'low' => ItsmImpact.low,
    'medium' => ItsmImpact.medium,
    'high' => ItsmImpact.high,
    'critical' => ItsmImpact.critical,
    _ => null,
  };
}

ItsmUrgency? _urgency(String value) {
  return switch (value.trim().toLowerCase()) {
    'low' => ItsmUrgency.low,
    'medium' => ItsmUrgency.medium,
    'high' => ItsmUrgency.high,
    _ => null,
  };
}

DateTime? _dateFromCursor(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _requireEmail(ItsmQueryPrincipal principal) {
  final email = principal.email.trim();
  if (email.isEmpty) {
    throw const ItsmRepositoryException(
      'The current session does not contain an email address.',
    );
  }
  return email;
}

String _requireUserId(ItsmQueryPrincipal principal) {
  final userId = principal.userId.trim();
  if (userId.isEmpty) {
    throw const ItsmRepositoryException(
      'The current session does not contain a user ID.',
    );
  }
  return userId;
}

String _firstNonEmpty(Iterable<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

String? _nullable(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
