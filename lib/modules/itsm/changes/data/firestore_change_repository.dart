import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/collaboration.dart';
import '../../shared/domain/itsm_audit_event.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../application/change_access_policy.dart';
import '../application/change_collaboration_access.dart';
import '../domain/changes_domain.dart';
import 'change_collaboration_mapper.dart';
import 'change_repository.dart';

class FirestoreChangeRepository implements ChangeRepository {
  FirestoreChangeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _changes =>
      _firestore.collection('changeRequests');

  CollectionReference<Map<String, dynamic>> get _calendar =>
      _firestore.collection('changeCalendarEntries');

  @override
  Future<PageResult<ChangeRequest>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ChangeRequestQuery query,
    required PageRequest page,
  }) async {
    _authorizeRequestScope(principal, query.scope);
    if (page.direction != PageDirection.forward) {
      throw const ChangeRepositoryException(
        'Change requests support forward pagination only.',
      );
    }
    final snapshot = await _requestQuery(
      principal: principal,
      query: query,
      cursor: page.cursor,
    ).limit(page.limit + 1).get();
    final hasMore = snapshot.docs.length > page.limit;
    final documents = hasMore
        ? snapshot.docs.take(page.limit).toList(growable: false)
        : snapshot.docs;
    return PageResult(
      items: documents.map(_requestFromDocument),
      hasMore: hasMore,
      nextCursor: hasMore && documents.isNotEmpty
          ? _updatedCursor(documents.last)
          : null,
    );
  }

  @override
  Stream<List<ChangeRequest>> watchFirstPage({
    required ItsmQueryPrincipal principal,
    required ChangeRequestQuery query,
    int limit = PageRequest.defaultLimit,
  }) {
    _authorizeRequestScope(principal, query.scope);
    _validateLimit(limit);
    return _requestQuery(principal: principal, query: query)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_requestFromDocument).toList(growable: false),
        );
  }

  @override
  Stream<ChangeRequest?> watchById({
    required ItsmQueryPrincipal principal,
    required String id,
  }) {
    final normalizedId = _requireId(id);
    return _changes.doc(normalizedId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final change = _requestFromDocument(snapshot);
      return _canReadRequest(principal, change) ? change : null;
    });
  }

  @override
  Stream<List<CabMeeting>> watchCabMeetings({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  }) {
    if (principal.role != ItsmRole.manager) {
      throw const ChangeRepositoryException(
        'CAB deliberations require MANAGER access.',
      );
    }
    _validateLimit(limit);
    return _changes
        .doc(_requireId(changeId))
        .collection('cabMeetings')
        .orderBy('scheduledStartAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => CabMeeting.fromMap(
                  document.id,
                  Map<String, Object?>.from(document.data()),
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<ChangeCalendarEntry>> watchCalendar({
    required ItsmQueryPrincipal principal,
    required ChangeCalendarQuery query,
    int limit = PageRequest.maximumLimit,
  }) {
    _authorizeCalendarScope(principal, query.scope);
    _validateLimit(limit);
    Query<Map<String, dynamic>> firestoreQuery = _calendar
        .where('plannedStartAt', isGreaterThanOrEqualTo: query.startsAt)
        .where('plannedStartAt', isLessThan: query.endsAt);
    firestoreQuery = switch (query.scope) {
      ChangeCalendarScope.operational => firestoreQuery,
      ChangeCalendarScope.executive =>
        firestoreQuery.where('publishMaintenance', isEqualTo: true),
      ChangeCalendarScope.ownAndPublished => firestoreQuery.where(
          Filter.or(
            Filter('requesterId', isEqualTo: principal.userId),
            Filter('publishMaintenance', isEqualTo: true),
          ),
        ),
    };
    final serviceId = query.serviceId?.trim();
    final ciId = query.configurationItemId?.trim();
    if (serviceId != null && serviceId.isNotEmpty) {
      firestoreQuery =
          firestoreQuery.where('affectedServiceIds', arrayContains: serviceId);
    } else if (ciId != null && ciId.isNotEmpty) {
      firestoreQuery =
          firestoreQuery.where('affectedCiIds', arrayContains: ciId);
    }
    if (query.type != null) {
      firestoreQuery =
          firestoreQuery.where('changeType', isEqualTo: query.type!.value);
    }
    if (query.status != null) {
      firestoreQuery =
          firestoreQuery.where('status', isEqualTo: query.status!.value);
    }
    if (query.hasConflict != null) {
      firestoreQuery = firestoreQuery.where(
        'hasConflict',
        isEqualTo: query.hasConflict,
      );
    }
    return firestoreQuery
        .orderBy('plannedStartAt')
        .orderBy(FieldPath.documentId)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => ChangeCalendarEntry.fromMap(
                  document.id,
                  Map<String, Object?>.from(document.data()),
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<ItsmComment>> watchComments({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  }) {
    final normalizedId = _requireId(changeId);
    final decision = ChangeCollaborationReadDecision.forPrincipal(principal);
    return _watchCollaboration(
      principal: principal,
      changeId: normalizedId,
      collectionName: 'comments',
      orderField: 'createdAt',
      limit: limit,
      include: (data) => decision.allowsComment(
        ChangeCollaborationMapper.commentVisibility(data),
      ),
      map: (id, data) =>
          ChangeCollaborationMapper.comment(id, normalizedId, data),
    );
  }

  @override
  Stream<List<ItsmAttachment>> watchAttachments({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  }) {
    final normalizedId = _requireId(changeId);
    final decision = ChangeCollaborationReadDecision.forPrincipal(principal);
    return _watchCollaboration(
      principal: principal,
      changeId: normalizedId,
      collectionName: 'attachments',
      orderField: 'createdAt',
      limit: limit,
      include: (data) => decision.allowsAttachment(
        ChangeCollaborationMapper.attachmentVisibility(data),
      ),
      map: (id, data) =>
          ChangeCollaborationMapper.attachment(id, normalizedId, data),
    );
  }

  @override
  Stream<List<ItsmAuditEvent>> watchAuditTimeline({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  }) {
    final normalizedId = _requireId(changeId);
    final decision = ChangeCollaborationReadDecision.forPrincipal(principal);
    return _watchCollaboration(
      principal: principal,
      changeId: normalizedId,
      collectionName: 'auditLogs',
      orderField: 'createdAt',
      limit: limit,
      include: decision.allowsAudit,
      map: (id, data) =>
          ChangeCollaborationMapper.auditEvent(id, normalizedId, data),
    );
  }

  Stream<List<T>> _watchCollaboration<T>({
    required ItsmQueryPrincipal principal,
    required String changeId,
    required String collectionName,
    required String orderField,
    required int limit,
    required bool Function(Map<String, Object?> data) include,
    required T Function(String id, Map<String, Object?> data) map,
  }) {
    _validateLimit(limit);
    final decision = ChangeCollaborationReadDecision.forPrincipal(principal);
    return Stream.fromFuture(
      _authorizeCollaborationParent(principal, changeId, decision),
    ).asyncExpand((_) {
      Query<Map<String, dynamic>> query =
          _changes.doc(changeId).collection(collectionName);
      if (decision.requiresRequesterVisibilityQuery) {
        query = query.where('isInternal', isEqualTo: false);
      }
      return query
          .orderBy(orderField, descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (document) => MapEntry(
                    document.id,
                    Map<String, Object?>.from(document.data()),
                  ),
                )
                .where((entry) => include(entry.value))
                .map((entry) => map(entry.key, entry.value))
                .toList(growable: false),
          );
    });
  }

  Future<void> _authorizeCollaborationParent(
    ItsmQueryPrincipal principal,
    String changeId,
    ChangeCollaborationReadDecision decision,
  ) async {
    if (!decision.requiresRequesterOwnership) return;
    final snapshot = await _changes.doc(changeId).get();
    final data = snapshot.data();
    if (data == null) {
      throw const ChangeRepositoryException(
          'The change request was not found.');
    }
    final requester = data['requester'];
    final requesterMap = requester is Map
        ? requester.map((key, value) => MapEntry(key.toString(), value))
        : const <String, Object?>{};
    final requesterId =
        (data['requesterId'] ?? requesterMap['userId'])?.toString().trim();
    if (requesterId != principal.userId) {
      throw const ChangeRepositoryException(
        'Requester collaboration is available only on the user\'s own change.',
      );
    }
  }

  Query<Map<String, dynamic>> _requestQuery({
    required ItsmQueryPrincipal principal,
    required ChangeRequestQuery query,
    PageCursor? cursor,
  }) {
    Query<Map<String, dynamic>> result = _changes;
    result = switch (query.scope) {
      ChangeRequestScope.myActive => result
          .where('requesterId', isEqualTo: principal.userId)
          .where('lifecycleState', isEqualTo: 'active'),
      ChangeRequestScope.myHistory => result
          .where('requesterId', isEqualTo: principal.userId)
          .where('lifecycleState', isEqualTo: 'closed'),
      ChangeRequestScope.managerActive =>
        result.where('lifecycleState', isEqualTo: 'active'),
      ChangeRequestScope.managerHistory =>
        result.where('lifecycleState', isEqualTo: 'closed'),
    };
    if (query.type != null) {
      result = result.where('changeType', isEqualTo: query.type!.value);
    }
    if (query.status != null) {
      result = result.where('status', isEqualTo: query.status!.value);
    }
    if (query.risk != null) {
      result = result.where('risk', isEqualTo: query.risk!.value);
    }
    result = result
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    final updatedAt = cursor?['updatedAt'];
    final id = cursor?['id'];
    if (updatedAt != null && id is String && id.isNotEmpty) {
      result = result.startAfter([updatedAt, id]);
    }
    return result;
  }

  void _authorizeRequestScope(
    ItsmQueryPrincipal principal,
    ChangeRequestScope scope,
  ) {
    final operational = scope == ChangeRequestScope.managerActive ||
        scope == ChangeRequestScope.managerHistory;
    if (operational && principal.role != ItsmRole.manager) {
      throw const ChangeRepositoryException(
        'Only a MANAGER can query operational changes.',
      );
    }
  }

  void _authorizeCalendarScope(
    ItsmQueryPrincipal principal,
    ChangeCalendarScope scope,
  ) {
    final allowed = switch (scope) {
      ChangeCalendarScope.operational => principal.role == ItsmRole.manager,
      ChangeCalendarScope.executive => principal.role == ItsmRole.admin,
      ChangeCalendarScope.ownAndPublished => true,
    };
    if (!allowed) {
      throw const ChangeRepositoryException('Calendar scope is not allowed.');
    }
  }

  bool _canReadRequest(ItsmQueryPrincipal principal, ChangeRequest change) =>
      principal.role == ItsmRole.manager ||
      change.requester.userId == principal.userId;

  ChangeRequest _requestFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) =>
      ChangeRequest.fromMap(
        document.id,
        Map<String, Object?>.from(document.data() ?? const {}),
      );

  PageCursor _updatedCursor(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) =>
      PageCursor({
        'updatedAt': document.data()['updatedAt'],
        'id': document.id,
      });

  void _validateLimit(int limit) {
    if (limit < 1 || limit > PageRequest.maximumLimit) {
      throw RangeError.range(limit, 1, PageRequest.maximumLimit, 'limit');
    }
  }

  String _requireId(String id) {
    final normalized = id.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A change ID is required.');
    }
    return normalized;
  }
}
