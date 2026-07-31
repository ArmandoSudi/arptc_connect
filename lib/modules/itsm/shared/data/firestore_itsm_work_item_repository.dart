import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/itsm_shared_domain.dart';
import 'itsm_work_item_repository.dart';

/// Reads the trusted, denormalized ITSM work-item index.
///
/// Cloud Functions own writes to this collection. Keeping this adapter focused
/// on bounded reads lets the backing read model evolve without coupling the UI
/// to each authoritative work-item collection.
class FirestoreItsmWorkItemRepository implements ItsmWorkItemRepository {
  FirestoreItsmWorkItemRepository(this._firestore);

  static const collectionName = 'itsmWorkItemIndex';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  @override
  Future<PageResult<ItsmWorkItemSummary>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemQuery query,
    required PageRequest page,
  }) async {
    if (page.direction != PageDirection.forward) {
      throw const ItsmUnsupportedQueryException(
        'The work-item index currently supports forward pagination only.',
      );
    }

    final requestedLimit = page.limit;
    final snapshot = await _baseQuery(principal, query)
        .startAfterCursor(page.cursor)
        .limit(requestedLimit + 1)
        .get();
    final hasMore = snapshot.docs.length > requestedLimit;
    final pageDocuments = snapshot.docs.take(requestedLimit).toList();
    final items = pageDocuments
        .map(ItsmWorkItemIndexMapper.fromDocument)
        .where(query.matches)
        .toList(growable: false);
    final lastDocument = pageDocuments.lastOrNull;

    return PageResult(
      items: items,
      hasMore: hasMore,
      nextCursor:
          hasMore && lastDocument != null ? _cursorFor(lastDocument) : null,
    );
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
    return _baseQuery(principal, query).limit(limit).snapshots().map(
          (snapshot) => snapshot.docs
              .map(ItsmWorkItemIndexMapper.fromDocument)
              .where(query.matches)
              .toList(growable: false),
        );
  }

  @override
  Stream<ItsmWorkItemSummary?> watchById({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemType type,
    required String id,
  }) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A work-item ID is required.');
    }
    return _collection.doc('${type.value}:$normalizedId').snapshots().map(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;
        final item = ItsmWorkItemIndexMapper.fromDocument(snapshot);
        return _canRead(principal, item) ? item : null;
      },
    );
  }

  Query<Map<String, dynamic>> _baseQuery(
    ItsmQueryPrincipal principal,
    ItsmWorkItemQuery query,
  ) {
    Query<Map<String, dynamic>> result = _collection;
    switch (query.scope) {
      case ItsmWorkItemScope.myActive:
        result = result
            .where('requesterId', isEqualTo: _userId(principal))
            .where('selfServiceVisible', isEqualTo: true)
            .where('confidentiality', isEqualTo: 'internal')
            .where('lifecycleState', isEqualTo: 'active');
      case ItsmWorkItemScope.myHistory:
        result = result
            .where('requesterId', isEqualTo: _userId(principal))
            .where('selfServiceVisible', isEqualTo: true)
            .where('confidentiality', isEqualTo: 'internal')
            .where(
          'lifecycleState',
          whereIn: const ['closed', 'archived', 'cancelled'],
        );
      case ItsmWorkItemScope.managerActive:
        _requireManager(principal);
        result = result
            .where('confidentiality', isEqualTo: 'internal')
            .where('lifecycleState', isEqualTo: 'active');
      case ItsmWorkItemScope.managerClosed:
        _requireManager(principal);
        result = result.where('confidentiality', isEqualTo: 'internal').where(
          'lifecycleState',
          whereIn: const ['closed', 'archived', 'cancelled'],
        );
      case ItsmWorkItemScope.assignedToMe:
        _requireManager(principal);
        result = result
            .where('assignedUserId', isEqualTo: _userId(principal))
            .where('confidentiality', isEqualTo: 'internal');
      case ItsmWorkItemScope.executiveSnapshot:
        throw const ItsmUnsupportedQueryException(
          'Executive dashboards must read report snapshots, not raw indexes.',
        );
    }

    return result
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  bool _canRead(ItsmQueryPrincipal principal, ItsmWorkItemSummary item) {
    if (item.confidentiality == ItsmConfidentiality.restricted) return false;
    return principal.role == ItsmRole.manager ||
        item.requesterId == principal.userId.trim();
  }

  String _userId(ItsmQueryPrincipal principal) {
    final userId = principal.userId.trim();
    if (userId.isEmpty) {
      throw const ItsmRepositoryException(
        'The current session does not contain a user ID.',
      );
    }
    return userId;
  }

  void _requireManager(ItsmQueryPrincipal principal) {
    if (principal.role != ItsmRole.manager) {
      throw const ItsmRepositoryException(
        'An operational work-item query requires the MANAGER role.',
      );
    }
  }

  PageCursor _cursorFor(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return PageCursor({
      'updatedAt': ItsmWorkItemIndexMapper.dateFromValue(
        document.data()['updatedAt'],
      ).toUtc().toIso8601String(),
      'documentId': document.id,
    });
  }
}

extension on Query<Map<String, dynamic>> {
  Query<Map<String, dynamic>> startAfterCursor(PageCursor? cursor) {
    if (cursor == null) return this;
    final updatedAt = ItsmWorkItemIndexMapper.nullableDateFromValue(
      cursor['updatedAt'],
    );
    final documentId = cursor['documentId']?.toString().trim() ?? '';
    if (updatedAt == null || documentId.isEmpty) {
      throw const ItsmUnsupportedQueryException(
        'Work-item index cursors require updatedAt and documentId values.',
      );
    }
    return startAfter([Timestamp.fromDate(updatedAt), documentId]);
  }
}

class ItsmWorkItemIndexMapper {
  const ItsmWorkItemIndexMapper._();

  static ItsmWorkItemSummary fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return fromMap(document.id, document.data() ?? const {});
  }

  static ItsmWorkItemSummary fromMap(
    String documentId,
    Map<String, Object?> map,
  ) {
    final parsedType = ItsmWorkItemType.tryParse(map['type']);
    if (parsedType == null) {
      throw ItsmRepositoryException(
        'Work-item index $documentId has an unsupported type.',
      );
    }
    final id = _string(map['id'], _entityIdFromDocument(documentId));
    final requesterId = _firstNonEmpty([
      _string(map['requesterId']),
      _string(map['affectedUserId']),
      _string(map['createdBy']),
    ]);
    final createdAt = dateFromValue(map['createdAt']);
    final updatedAt = nullableDateFromValue(map['updatedAt']) ?? createdAt;
    final createdBy = _firstNonEmpty([
      _string(map['createdBy']),
      _string(map['createdByUserId']),
      requesterId,
    ]);

    return ItsmWorkItemSummary(
      id: id,
      reference: _firstNonEmpty([
        _string(map['reference']),
        _string(map['ticketNumber']),
        _string(map['requestNumber']),
        id,
      ]),
      type: parsedType,
      title: _firstNonEmpty([_string(map['title']), 'Untitled work item']),
      description: _string(map['description']),
      requesterId: requesterId,
      affectedUserId: _nullable(map['affectedUserId']),
      departmentId: _nullable(map['departmentId']),
      serviceId: _nullable(map['serviceId']),
      locationId: _nullable(map['locationId']),
      assignedGroupId: _nullable(map['assignedGroupId']),
      assignedUserId: _nullable(map['assignedUserId']),
      priority: ItsmPriority.fromValue(map['priority']),
      impact: _impact(map['impact']),
      urgency: _urgency(map['urgency']),
      status: _firstNonEmpty([_string(map['status']), 'unknown']),
      lifecycleState: ItsmLifecycleState.tryParse(map['lifecycleState']) ??
          ItsmLifecycleState.active,
      workflowDefinitionId: _nullable(map['workflowDefinitionId']),
      workflowVersion: _positiveInt(map['workflowVersion']),
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: _firstNonEmpty([
        _string(map['updatedBy']),
        _string(map['updatedByUserId']),
        createdBy,
      ]),
      dueAt: nullableDateFromValue(map['dueAt']),
      closedAt: nullableDateFromValue(map['closedAt']),
      confidentiality: ItsmConfidentiality.fromValue(map['confidentiality']),
      linkedAssetIds: _stringList(map['linkedAssetIds']),
      linkedCiIds: _stringList(map['linkedCiIds']),
    );
  }

  static DateTime dateFromValue(Object? value) {
    return nullableDateFromValue(value) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static DateTime? nullableDateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  static String _entityIdFromDocument(String documentId) {
    final separator = documentId.indexOf(':');
    return separator < 0 ? documentId : documentId.substring(separator + 1);
  }

  static String _string(Object? value, [String fallback = '']) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  static String? _nullable(Object? value) {
    final normalized = _string(value);
    return normalized.isEmpty ? null : normalized;
  }

  static String _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static int? _positiveInt(Object? value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static ItsmImpact? _impact(Object? value) {
    final normalized = _string(value).toLowerCase();
    for (final impact in ItsmImpact.values) {
      if (impact.value == normalized) return impact;
    }
    return null;
  }

  static ItsmUrgency? _urgency(Object? value) {
    final normalized = _string(value).toLowerCase();
    for (final urgency in ItsmUrgency.values) {
      if (urgency.value == normalized) return urgency;
    }
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => _string(item))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
