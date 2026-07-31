import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/support_domain.dart';
import 'service_request_repository.dart';

class FirestoreServiceRequestRepository implements ServiceRequestRepository {
  FirestoreServiceRequestRepository(this._firestore);

  static const int maximumLiveRequests = 100;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('serviceRequests');

  @override
  Future<PageResult<ServiceRequest>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ServiceRequestQuery query,
    required PageRequest page,
  }) async {
    _authorizeScope(principal, query.scope);
    if (page.direction != PageDirection.forward) {
      throw const ServiceRequestRepositoryException(
        'Service requests support forward cursor pagination only.',
      );
    }
    final snapshot = await _queryFor(
      principal: principal,
      scope: query.scope,
      cursor: page.cursor,
    ).limit(page.limit + 1).get();
    final hasMore = snapshot.docs.length > page.limit;
    final documents = hasMore
        ? snapshot.docs.take(page.limit).toList(growable: false)
        : snapshot.docs;
    final items = documents
        .map(_fromDocument)
        .where(query.matches)
        .where((request) => _canRead(principal, request))
        .toList(growable: false);
    final lastDocument = documents.isEmpty ? null : documents.last;
    return PageResult(
      items: items,
      hasMore: hasMore,
      nextCursor:
          hasMore && lastDocument != null ? _cursor(lastDocument) : null,
    );
  }

  @override
  Stream<List<ServiceRequest>> watchFirstPage({
    required ItsmQueryPrincipal principal,
    required ServiceRequestQuery query,
    required int limit,
  }) {
    _authorizeScope(principal, query.scope);
    if (limit < 1 || limit > PageRequest.maximumLimit) {
      throw RangeError.range(
        limit,
        1,
        PageRequest.maximumLimit,
        'limit',
      );
    }
    return _queryFor(principal: principal, scope: query.scope)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(_fromDocument)
              .where(query.matches)
              .where((request) => _canRead(principal, request))
              .toList(growable: false),
        );
  }

  @override
  Stream<ServiceRequest?> watchById({
    required ItsmQueryPrincipal principal,
    required String id,
  }) {
    final normalizedId = _requireId(id);
    return _requests.doc(normalizedId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final request = _fromDocument(snapshot);
      return _canRead(principal, request) ? request : null;
    });
  }

  @override
  Stream<ServiceRequestDetail?> watchDetail({
    required ItsmQueryPrincipal principal,
    required String id,
    int childLimit = 100,
  }) {
    final normalizedId = _requireId(id);
    if (childLimit < 1 || childLimit > PageRequest.maximumLimit) {
      throw RangeError.range(
        childLimit,
        1,
        PageRequest.maximumLimit,
        'childLimit',
      );
    }
    final document = _requests.doc(normalizedId);
    late final StreamController<ServiceRequestDetail?> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    ServiceRequest? request;
    var approvals = const <ServiceRequestApprovalSummary>[];
    var tasks = const <ServiceRequestTaskSummary>[];
    var comments = const <ServiceRequestComment>[];
    var attachments = const <ServiceRequestAttachment>[];
    var requestReady = false;
    var approvalsReady = false;
    var tasksReady = false;
    var commentsReady = false;
    var attachmentsReady = false;

    void emitIfReady() {
      if (!requestReady) return;
      final current = request;
      if (current == null) {
        controller.add(null);
        return;
      }
      if (!approvalsReady ||
          !tasksReady ||
          !commentsReady ||
          !attachmentsReady) {
        return;
      }
      controller.add(
        ServiceRequestDetail(
          request: current,
          approvals: approvals,
          tasks: tasks,
          comments: comments,
          attachments: attachments,
        ),
      );
    }

    void addError(Object error, StackTrace stackTrace) {
      controller.addError(error, stackTrace);
    }

    controller = StreamController<ServiceRequestDetail?>(
      onListen: () {
        subscriptions.add(
          document.snapshots().listen(
            (snapshot) {
              requestReady = true;
              if (!snapshot.exists) {
                request = null;
              } else {
                final parsed = _fromDocument(snapshot);
                request = _canRead(principal, parsed) ? parsed : null;
              }
              emitIfReady();
            },
            onError: addError,
          ),
        );
        subscriptions.add(
          document
              .collection('approvals')
              .orderBy('step')
              .limit(childLimit)
              .snapshots()
              .listen(
            (snapshot) {
              approvalsReady = true;
              approvals = snapshot.docs
                  .map(
                    (doc) => ServiceRequestApprovalSummary.fromMap(
                      doc.id,
                      Map<String, Object?>.from(doc.data()),
                    ),
                  )
                  .toList(growable: false);
              emitIfReady();
            },
            onError: addError,
          ),
        );
        subscriptions.add(
          _visibleChildQuery(
            document.collection('tasks'),
            principal,
          )
              .orderBy('createdAt', descending: true)
              .limit(childLimit)
              .snapshots()
              .listen(
            (snapshot) {
              tasksReady = true;
              tasks = snapshot.docs
                  .map(
                    (doc) => ServiceRequestTaskSummary.fromMap(
                      doc.id,
                      Map<String, Object?>.from(doc.data()),
                    ),
                  )
                  .toList(growable: false);
              emitIfReady();
            },
            onError: addError,
          ),
        );
        subscriptions.add(
          _visibleChildQuery(
            document.collection('comments'),
            principal,
          )
              .orderBy('createdAt', descending: true)
              .limit(childLimit)
              .snapshots()
              .listen(
            (snapshot) {
              commentsReady = true;
              comments = snapshot.docs
                  .map(
                    (doc) => ServiceRequestComment.fromMap(
                      doc.id,
                      Map<String, Object?>.from(doc.data()),
                    ),
                  )
                  .toList(growable: false);
              emitIfReady();
            },
            onError: addError,
          ),
        );
        subscriptions.add(
          _visibleChildQuery(
            document.collection('attachments'),
            principal,
          )
              .orderBy('createdAt', descending: true)
              .limit(childLimit)
              .snapshots()
              .listen(
            (snapshot) {
              attachmentsReady = true;
              attachments = snapshot.docs
                  .map(
                    (doc) => ServiceRequestAttachment.fromMap(
                      doc.id,
                      normalizedId,
                      Map<String, Object?>.from(doc.data()),
                    ),
                  )
                  .toList(growable: false);
              emitIfReady();
            },
            onError: addError,
          ),
        );
      },
      onCancel: () async {
        await Future.wait(
          subscriptions.map((subscription) => subscription.cancel()),
        );
      },
    );
    return controller.stream;
  }

  Query<Map<String, dynamic>> _queryFor({
    required ItsmQueryPrincipal principal,
    required ServiceRequestScope scope,
    PageCursor? cursor,
  }) {
    Query<Map<String, dynamic>> query = _requests;
    query = switch (scope) {
      ServiceRequestScope.myActive => query
          .where('affectedUserId', isEqualTo: principal.userId)
          .where('lifecycleState', isEqualTo: ItsmLifecycleState.active.value),
      ServiceRequestScope.myHistory =>
        query.where('affectedUserId', isEqualTo: principal.userId).where(
          'lifecycleState',
          whereIn: const ['closed', 'archived', 'cancelled'],
        ),
      ServiceRequestScope.managerActive => query.where(
          'lifecycleState',
          isEqualTo: ItsmLifecycleState.active.value,
        ),
      ServiceRequestScope.managerClosed => query.where(
          'lifecycleState',
          whereIn: const ['closed', 'archived', 'cancelled'],
        ),
      ServiceRequestScope.assignedToMe =>
        query.where('assignedUserId', isEqualTo: principal.userId),
    };
    query = query
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (cursor != null) {
      final updatedAt = _cursorDate(cursor['updatedAt']);
      final documentId = cursor['documentId']?.toString().trim() ?? '';
      if (updatedAt == null || documentId.isEmpty) {
        throw const ServiceRequestRepositoryException(
          'Request cursors require updatedAt and documentId.',
        );
      }
      query = query.startAfter([Timestamp.fromDate(updatedAt), documentId]);
    }
    return query;
  }

  Query<Map<String, dynamic>> _visibleChildQuery(
    CollectionReference<Map<String, dynamic>> collection,
    ItsmQueryPrincipal principal,
  ) {
    return principal.role == ItsmRole.manager
        ? collection
        : collection.where('isInternal', isEqualTo: false);
  }

  ServiceRequest _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw const ServiceRequestRepositoryException(
        'A service request document has no data.',
      );
    }
    return ServiceRequest.fromMap(
      document.id,
      Map<String, Object?>.from(data),
    );
  }

  bool _canRead(
    ItsmQueryPrincipal principal,
    ServiceRequest request,
  ) {
    if (principal.role == ItsmRole.manager) return true;
    return request.selfServiceVisible &&
        request.confidentiality != ItsmConfidentiality.restricted &&
        request.requestedForUserId == principal.userId;
  }

  void _authorizeScope(
    ItsmQueryPrincipal principal,
    ServiceRequestScope scope,
  ) {
    final operational = scope == ServiceRequestScope.managerActive ||
        scope == ServiceRequestScope.managerClosed ||
        scope == ServiceRequestScope.assignedToMe;
    if (operational && principal.role != ItsmRole.manager) {
      throw ServiceRequestRepositoryException(
        'Role ${principal.role.value} cannot query ${scope.name}.',
      );
    }
  }

  PageCursor _cursor(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final updatedAt = _cursorDate(document.data()['updatedAt']);
    if (updatedAt == null) {
      throw const ServiceRequestRepositoryException(
        'Every request page requires an updatedAt value.',
      );
    }
    return PageCursor({
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'documentId': document.id,
    });
  }

  DateTime? _cursorDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _requireId(String id) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A service request ID is required.');
    }
    return normalizedId;
  }
}
