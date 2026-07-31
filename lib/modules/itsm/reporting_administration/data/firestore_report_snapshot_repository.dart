import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/dashboard_snapshot.dart';
import 'firestore_repository_support.dart';
import 'report_snapshot_repository.dart';

class FirestoreReportSnapshotRepository implements ReportSnapshotRepository {
  FirestoreReportSnapshotRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _snapshots =>
      _firestore.collection('itsmReportSnapshots');

  @override
  Stream<ItsmReportSnapshot?> watchCurrent({
    required ItsmQueryPrincipal principal,
    required ReportSnapshotQuery query,
  }) {
    _authorize(principal, query);
    return _query(query)
        .where('periodGranularity', isEqualTo: 'current')
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty
            ? null
            : ItsmReportSnapshot.fromMap(
                snapshot.docs.first.id,
                Map<String, Object?>.from(snapshot.docs.first.data()),
              ));
  }

  @override
  Future<PageResult<ItsmReportSnapshot>> fetchHistory({
    required ItsmQueryPrincipal principal,
    required ReportSnapshotQuery query,
    required PageRequest page,
  }) async {
    _authorize(principal, query);
    requireForwardPage(page);
    Query<Map<String, dynamic>> firestoreQuery =
        _query(query).orderBy('periodStart', descending: true).orderBy(
              FieldPath.documentId,
              descending: true,
            );
    firestoreQuery = applyDescendingCursor(
      firestoreQuery,
      page.cursor,
      'periodStart',
    );
    final result = await firestoreQuery.limit(page.limit + 1).get();
    final hasMore = result.docs.length > page.limit;
    final documents = result.docs.take(page.limit).toList(growable: false);
    return PageResult(
      items: documents
          .map((document) => ItsmReportSnapshot.fromMap(
                document.id,
                Map<String, Object?>.from(document.data()),
              ))
          .toList(growable: false),
      hasMore: hasMore,
      nextCursor: hasMore && documents.isNotEmpty
          ? documentCursor(documents.last, 'periodStart')
          : null,
    );
  }

  Query<Map<String, dynamic>> _query(ReportSnapshotQuery query) {
    Query<Map<String, dynamic>> result = _snapshots
        .where('audience', isEqualTo: query.audience.value)
        .where('snapshotType', isEqualTo: query.type.value);
    if (query.scopeType?.trim().isNotEmpty == true) {
      result = result.where('scopeType', isEqualTo: query.scopeType!.trim());
    }
    if (query.scopeId?.trim().isNotEmpty == true) {
      result = result.where('scopeId', isEqualTo: query.scopeId!.trim());
    }
    return result;
  }

  void _authorize(ItsmQueryPrincipal principal, ReportSnapshotQuery query) {
    validateReadRole(principal.role, principal.role != ItsmRole.user);
    if (principal.role != query.audience) {
      throw const ReportingAdministrationRepositoryException(
        'A principal may read only snapshots for their audience.',
      );
    }
    if (query.audience == ItsmRole.manager &&
        query.type == ReportSnapshotType.executive) {
      throw const ReportingAdministrationRepositoryException(
        'MANAGER cannot read executive snapshots.',
      );
    }
    if (query.audience == ItsmRole.admin &&
        query.type == ReportSnapshotType.operational) {
      throw const ReportingAdministrationRepositoryException(
        'ADMIN cannot read operational snapshots.',
      );
    }
  }
}
