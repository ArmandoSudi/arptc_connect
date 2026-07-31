import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/sla_configuration.dart';
import 'firestore_repository_support.dart';
import 'sla_policy_repository.dart';

class FirestoreSlaPolicyRepository implements SlaPolicyRepository {
  FirestoreSlaPolicyRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _policies =>
      _firestore.collection('slaPolicies');

  @override
  Future<PageResult<SlaPolicyConfiguration>> fetchPolicies({
    required ItsmQueryPrincipal principal,
    required SlaPolicyQuery query,
    required PageRequest page,
  }) =>
      _fetchParents(
        principal: principal,
        page: page,
        build: (base) {
          Query<Map<String, dynamic>> result = base;
          if (principal.role == ItsmRole.admin) {
            result =
                result.where('status', whereIn: const ['published', 'retired']);
          } else if (query.status != null) {
            result = result.where('status', isEqualTo: query.status!.value);
          }
          if (query.workItemType != null) {
            result = result.where('workItemType',
                isEqualTo: query.workItemType!.value);
          } else if (query.serviceId?.trim().isNotEmpty == true) {
            result =
                result.where('serviceId', isEqualTo: query.serviceId!.trim());
          }
          return result;
        },
      );

  Future<PageResult<SlaPolicyConfiguration>> _fetchParents({
    required ItsmQueryPrincipal principal,
    required PageRequest page,
    required Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)
        build,
  }) async {
    _authorize(principal);
    requireForwardPage(page);
    var query = build(_policies)
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    query = applyDescendingCursor(query, page.cursor, 'updatedAt');
    final snapshot = await query.limit(page.limit + 1).get();
    final hasMore = snapshot.docs.length > page.limit;
    final docs = snapshot.docs.take(page.limit).toList(growable: false);
    return PageResult(
      items: docs.map((doc) => SlaPolicyConfiguration.fromMap(
          doc.id, Map<String, Object?>.from(doc.data()))),
      hasMore: hasMore,
      nextCursor: hasMore && docs.isNotEmpty
          ? documentCursor(docs.last, 'updatedAt')
          : null,
    );
  }

  @override
  Stream<SlaPolicyConfiguration?> watchPolicy({
    required ItsmQueryPrincipal principal,
    required String policyId,
  }) {
    _authorize(principal);
    return _policies.doc(policyId.trim()).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final policy = SlaPolicyConfiguration.fromMap(
          doc.id, Map<String, Object?>.from(data));
      if (principal.role == ItsmRole.admin &&
          policy.status == ItsmPublicationState.draft) return null;
      return policy;
    });
  }

  @override
  Future<PageResult<SlaPolicyVersionConfiguration>> fetchVersions({
    required ItsmQueryPrincipal principal,
    required String policyId,
    required PageRequest page,
  }) async {
    _authorize(principal);
    requireForwardPage(page);
    Query<Map<String, dynamic>> query =
        _policies.doc(policyId.trim()).collection('versions');
    if (principal.role == ItsmRole.admin) {
      query = query.where('status', whereIn: const ['published', 'retired']);
    }
    query = query
        .orderBy('version', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (page.cursor != null) {
      query = query.startAfter([page.cursor!['version'], page.cursor!['id']]);
    }
    final snapshot = await query.limit(page.limit + 1).get();
    final hasMore = snapshot.docs.length > page.limit;
    final docs = snapshot.docs.take(page.limit).toList(growable: false);
    return PageResult(
      items: docs.map((doc) => SlaPolicyVersionConfiguration.fromMap(
          policyId, doc.id, Map<String, Object?>.from(doc.data()))),
      hasMore: hasMore,
      nextCursor: hasMore && docs.isNotEmpty
          ? PageCursor(
              {'version': docs.last.data()['version'], 'id': docs.last.id})
          : null,
    );
  }

  void _authorize(ItsmQueryPrincipal principal) =>
      validateReadRole(principal.role, principal.role != ItsmRole.user);
}
