import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../application/security_compliance_access.dart';
import '../domain/security_compliance_domain.dart';
import 'security_compliance_evidence_sanitizer.dart';
import 'security_compliance_query_contract.dart';
import 'security_compliance_repository.dart';

class FirestoreSecurityComplianceRepository
    implements SecurityComplianceRepository {
  FirestoreSecurityComplianceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<int> fetchRevision({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceIdentity identity,
  }) async {
    final collection = switch (identity.type) {
      SecurityComplianceEntityType.finding =>
        SecurityComplianceQueryContract.findingsCollection,
      SecurityComplianceEntityType.exception =>
        SecurityComplianceQueryContract.exceptionsCollection,
      SecurityComplianceEntityType.campaign =>
        SecurityComplianceQueryContract.campaignsCollection,
      SecurityComplianceEntityType.reviewItem =>
        SecurityComplianceQueryContract.reviewItemsCollection,
    };
    if (identity.scope == SecurityComplianceScope.operational) {
      _requireManager(principal);
    } else {
      _requireSelfService(principal);
    }
    final snapshot =
        await _firestore.collection(collection).doc(identity.id).get();
    if (!snapshot.exists) {
      throw const SecurityComplianceRepositoryException(
        'The security record no longer exists.',
      );
    }
    final data = Map<String, Object?>.from(snapshot.data()!);
    if (identity.scope == SecurityComplianceScope.selfService) {
      final visible = data['selfServiceVisible'] == true;
      final ownerId = identity.type == SecurityComplianceEntityType.exception
          ? _nestedUserId(data['requester'])
          : identity.type == SecurityComplianceEntityType.reviewItem
              ? _nestedUserId(data['subjectUser'])
              : '';
      if (!visible || ownerId != principal.userId) {
        throw const SecurityComplianceRepositoryException(
          'The security record is outside the active self-service scope.',
        );
      }
    }
    final revision = data['revision'];
    if (revision is int && revision >= 0) return revision;
    if (revision is num && revision >= 0) return revision.toInt();
    throw const SecurityComplianceRepositoryException(
      'The security record has no valid revision.',
    );
  }

  @override
  Future<PageResult<SecurityFinding>> fetchFindings({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  }) {
    _requireManager(principal);
    return _fetchPage(
      query: _filteredQuery(
        _firestore
            .collection(SecurityComplianceQueryContract.findingsCollection),
        request.query,
        statusField: 'status',
        secondaryField: 'severity',
      ),
      page: request.page,
      orderField: 'updatedAt',
      map: (document) => SecurityFinding.fromMap(
        document.id,
        SecurityComplianceEvidenceSanitizer.sanitize(
            document.data(), principal),
      ),
    );
  }

  @override
  Stream<List<SecurityFinding>> watchFindings({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  }) {
    _requireManager(principal);
    return _watchPage(
      query: _filteredQuery(
        _firestore
            .collection(SecurityComplianceQueryContract.findingsCollection),
        request.query,
        statusField: 'status',
        secondaryField: 'severity',
      ),
      limit: request.limit,
      orderField: 'updatedAt',
      map: (document) => SecurityFinding.fromMap(
        document.id,
        SecurityComplianceEvidenceSanitizer.sanitize(
            document.data(), principal),
      ),
    );
  }

  @override
  Future<PageResult<SecurityException>> fetchExceptions({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  }) {
    final query = _exceptionQuery(principal, request.query);
    return _fetchPage(
      query: query,
      page: request.page,
      orderField: 'updatedAt',
      map: (document) => SecurityException.fromMap(
        document.id,
        SecurityComplianceEvidenceSanitizer.sanitize(
            document.data(), principal),
      ),
    );
  }

  @override
  Stream<List<SecurityException>> watchExceptions({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  }) {
    return _watchPage(
      query: _exceptionQuery(principal, request.query),
      limit: request.limit,
      orderField: 'updatedAt',
      map: (document) => SecurityException.fromMap(
        document.id,
        SecurityComplianceEvidenceSanitizer.sanitize(
            document.data(), principal),
      ),
    );
  }

  @override
  Future<PageResult<AssetComplianceAssessment>> fetchAssessments({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  }) {
    _requireManager(principal);
    return _fetchPage(
      query: _filteredQuery(
        _firestore
            .collection(SecurityComplianceQueryContract.assessmentsCollection),
        request.query,
        statusField: 'result',
        secondaryField: 'assignedUserId',
      ),
      page: request.page,
      orderField: 'updatedAt',
      map: (document) => AssetComplianceAssessment.fromMap(
        document.id,
        SecurityComplianceEvidenceSanitizer.sanitize(
            document.data(), principal),
      ),
    );
  }

  @override
  Stream<List<AssetComplianceAssessment>> watchAssessments({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  }) {
    _requireManager(principal);
    return _watchPage(
      query: _filteredQuery(
        _firestore
            .collection(SecurityComplianceQueryContract.assessmentsCollection),
        request.query,
        statusField: 'result',
        secondaryField: 'assignedUserId',
      ),
      limit: request.limit,
      orderField: 'updatedAt',
      map: (document) => AssetComplianceAssessment.fromMap(
        document.id,
        SecurityComplianceEvidenceSanitizer.sanitize(
            document.data(), principal),
      ),
    );
  }

  @override
  Future<PageResult<OwnDeviceComplianceProjection>> fetchOwnCompliance({
    required ItsmQueryPrincipal principal,
    required PageRequest page,
  }) {
    _requireOwnCompliance(principal);
    return _fetchPage(
      query: _firestore
          .collection(
              SecurityComplianceQueryContract.selfServiceComplianceCollection)
          .where('assignedUserId', isEqualTo: principal.userId),
      page: page,
      orderField: 'updatedAt',
      map: (document) => OwnDeviceComplianceProjection.fromMap(
        document.id,
        Map<String, Object?>.from(document.data()),
      ),
    );
  }

  @override
  Stream<List<OwnDeviceComplianceProjection>> watchOwnCompliance({
    required ItsmQueryPrincipal principal,
    int limit = PageRequest.defaultLimit,
  }) {
    _requireOwnCompliance(principal);
    return _watchPage(
      query: _firestore
          .collection(
              SecurityComplianceQueryContract.selfServiceComplianceCollection)
          .where('assignedUserId', isEqualTo: principal.userId),
      limit: limit,
      orderField: 'updatedAt',
      map: (document) => OwnDeviceComplianceProjection.fromMap(
        document.id,
        Map<String, Object?>.from(document.data()),
      ),
    );
  }

  @override
  Future<PageResult<AccessReviewCampaign>> fetchCampaigns({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  }) {
    _requireManager(principal);
    return _fetchPage(
      query: _filteredQuery(
        _firestore
            .collection(SecurityComplianceQueryContract.campaignsCollection),
        request.query,
        statusField: 'status',
      ),
      page: request.page,
      orderField: 'updatedAt',
      map: (document) => AccessReviewCampaign.fromMap(
        document.id,
        Map<String, Object?>.from(document.data()),
      ),
    );
  }

  @override
  Stream<List<AccessReviewCampaign>> watchCampaigns({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  }) {
    _requireManager(principal);
    return _watchPage(
      query: _filteredQuery(
        _firestore
            .collection(SecurityComplianceQueryContract.campaignsCollection),
        request.query,
        statusField: 'status',
      ),
      limit: request.limit,
      orderField: 'updatedAt',
      map: (document) => AccessReviewCampaign.fromMap(
        document.id,
        Map<String, Object?>.from(document.data()),
      ),
    );
  }

  @override
  Future<PageResult<AccessReviewItem>> fetchAccessReviewItems({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  }) {
    return _fetchPage(
      query: _accessReviewQuery(principal, request.query),
      page: request.page,
      orderField: 'updatedAt',
      map: (document) => AccessReviewItem.fromMap(
        document.id,
        SecurityComplianceEvidenceSanitizer.sanitize(
            document.data(), principal),
      ),
    );
  }

  @override
  Stream<List<AccessReviewItem>> watchAccessReviewItems({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  }) {
    return _watchPage(
      query: _accessReviewQuery(principal, request.query),
      limit: request.limit,
      orderField: 'updatedAt',
      map: (document) => AccessReviewItem.fromMap(
        document.id,
        SecurityComplianceEvidenceSanitizer.sanitize(
            document.data(), principal),
      ),
    );
  }

  @override
  Stream<List<AccessCorrectionRequest>> watchCorrectionRequests({
    required ItsmQueryPrincipal principal,
    int limit = PageRequest.defaultLimit,
  }) {
    _validateLimit(limit);
    Query<Map<String, dynamic>> query = _firestore.collectionGroup(
      SecurityComplianceQueryContract.correctionsCollectionGroup,
    );
    if (principal.role != ItsmRole.manager) {
      _requireSelfService(principal);
      query = query.where('requestedBy', isEqualTo: principal.userId);
    }
    return query
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((document) {
            final data = Map<String, Object?>.from(document.data());
            data['id'] = document.id;
            data['accessReviewItemId'] ??= document.reference.parent.parent?.id;
            return AccessCorrectionRequest.fromMap(data);
          }).toList(growable: false),
        );
  }

  Query<Map<String, dynamic>> _exceptionQuery(
    ItsmQueryPrincipal principal,
    SecurityComplianceQuery request,
  ) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(SecurityComplianceQueryContract.exceptionsCollection);
    if (request.scope == SecurityComplianceScope.operational) {
      _requireManager(principal);
    } else {
      if (principal.role == ItsmRole.manager) {
        query = query
            .where('requester.userId', isEqualTo: principal.userId)
            .where('selfServiceVisible', isEqualTo: true);
      } else {
        _requireSelfService(principal);
        query = query
            .where('requester.userId', isEqualTo: principal.userId)
            .where('selfServiceVisible', isEqualTo: true);
      }
    }
    return _filteredQuery(
      query,
      request,
      statusField: 'status',
      secondaryField: 'affectedServiceId',
    );
  }

  Query<Map<String, dynamic>> _accessReviewQuery(
    ItsmQueryPrincipal principal,
    SecurityComplianceQuery request,
  ) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(SecurityComplianceQueryContract.reviewItemsCollection);
    if (request.scope == SecurityComplianceScope.operational) {
      _requireManager(principal);
    } else {
      _requireSelfService(principal);
      query = query
          .where('subjectUser.userId', isEqualTo: principal.userId)
          .where('selfServiceVisible', isEqualTo: true);
    }
    return _filteredQuery(
      query,
      request,
      statusField: 'completionStatus',
      secondaryField: 'campaignId',
    );
  }

  Query<Map<String, dynamic>> _filteredQuery(
    Query<Map<String, dynamic>> query,
    SecurityComplianceQuery request, {
    required String statusField,
    String? secondaryField,
  }) {
    final status = request.status?.trim();
    final secondary = request.secondaryFilter?.trim();
    if (status != null && status.isNotEmpty) {
      return query.where(statusField, isEqualTo: status);
    }
    if (secondaryField != null && secondary != null && secondary.isNotEmpty) {
      return query.where(secondaryField, isEqualTo: secondary);
    }
    return query;
  }

  Future<PageResult<T>> _fetchPage<T>({
    required Query<Map<String, dynamic>> query,
    required PageRequest page,
    required String orderField,
    required T Function(QueryDocumentSnapshot<Map<String, dynamic>>) map,
  }) async {
    _validatePage(page);
    Query<Map<String, dynamic>> ordered = query
        .orderBy(orderField, descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    final cursor = page.cursor;
    if (cursor != null) {
      ordered = ordered.startAfter([cursor['sortAt'], cursor['id']]);
    }
    final snapshot = await ordered.limit(page.limit + 1).get();
    final hasMore = snapshot.docs.length > page.limit;
    final documents = hasMore
        ? snapshot.docs.take(page.limit).toList(growable: false)
        : snapshot.docs;
    return PageResult<T>(
      items: documents.map(map),
      hasMore: hasMore,
      nextCursor: hasMore && documents.isNotEmpty
          ? PageCursor({
              'sortAt': documents.last.data()[orderField],
              'id': documents.last.id,
            })
          : null,
    );
  }

  Stream<List<T>> _watchPage<T>({
    required Query<Map<String, dynamic>> query,
    required int limit,
    required String orderField,
    required T Function(QueryDocumentSnapshot<Map<String, dynamic>>) map,
  }) {
    _validateLimit(limit);
    return query
        .orderBy(orderField, descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(map).toList(growable: false),
        );
  }

  void _requireManager(ItsmQueryPrincipal principal) {
    if (principal.role != ItsmRole.manager) {
      throw const SecurityComplianceRepositoryException(
        'MANAGER access is required for operational security records.',
      );
    }
  }

  void _requireSelfService(ItsmQueryPrincipal principal) {
    if (principal.role != ItsmRole.user && principal.role != ItsmRole.admin) {
      throw const SecurityComplianceRepositoryException(
        'USER or ADMIN self-service access is required.',
      );
    }
  }

  void _requireOwnCompliance(ItsmQueryPrincipal principal) {
    if (principal.role != ItsmRole.user) {
      throw const SecurityComplianceRepositoryException(
        'Own-device compliance is available to USER self-service only.',
      );
    }
  }

  void _validatePage(PageRequest page) {
    if (page.direction != PageDirection.forward) {
      throw const SecurityComplianceRepositoryException(
        'Security and compliance lists support forward pagination only.',
      );
    }
    _validateLimit(page.limit);
  }

  void _validateLimit(int limit) {
    if (limit < 1 || limit > PageRequest.maximumLimit) {
      throw RangeError.range(limit, 1, PageRequest.maximumLimit, 'limit');
    }
  }

  String _nestedUserId(Object? value) {
    if (value is! Map) return '';
    return value['userId']?.toString().trim() ?? '';
  }
}
